//
//  AudioManager.m
//  VideoChatDemo
//
//  Created by menthu on 2022/8/23.
//  Copyright © 2022 menthu. All rights reserved.
//

#import "AudioManager.h"
#import <UIKit/UIKit.h>
#import "AudioHelper.h"
#import "AudioFileWrite.h"

#define NO_MORE_AUDIO_DATA -101

@interface AudioManager (){
//    AudioStreamPacketDescription _outputPacketsDesc[2048];
}


@property (nonatomic, strong) NSMutableData *pcmData;
@property (nonatomic, strong) NSMutableData *converPcmData;

@property (nonatomic, assign) unsigned int sampleRate;
@property (nonatomic, assign) int channels;
@property (nonatomic, assign) int bitsPerChannel;

@property (nonatomic, assign) AudioComponentInstance audioUnit;

@property (nonatomic, assign) int byteRate;
@property (nonatomic, assign) BOOL paused;


@property (nonatomic, assign) NSUInteger currentSampleNum;//积累的sample个数
@property (nonatomic, assign) NSUInteger totalSampleNum;//积累的sample个数
@property (nonatomic, assign) AudioStreamBasicDescription sourceAudioDesc;
@property (nonatomic, assign) AudioStreamBasicDescription converAudioDesc;
@property (nonatomic, assign) AudioConverterRef audioConverterRef;
@property (nonatomic, assign) AudioBufferList converAudioBufferList;
@property (nonatomic, assign) int converCount;//转码次数

@property (nonatomic, assign) BOOL allowProvidaMoreAudioData;

@end

@implementation AudioManager

static id _instance = nil;
+ (instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init{
    if (self = [super init]) {
        self.paused = NO;
        self.pcmData = [NSMutableData data];
        self.converPcmData = [NSMutableData data];
        self.allowProvidaMoreAudioData = NO;
        self.totalSampleNum = 0;
    }
    return self;
}

- (void)dealloc{
    AudioConverterDispose(self.audioConverterRef);
}

- (void)startRecordWithSampleRate:(unsigned int)sampleRate channels:(int)channels bitsPerChannel:(int)bitsPerChannel{
    [self requestGrantedIfNeed:^(BOOL granted) {
        self.sampleRate = sampleRate;
        self.channels = channels;
        self.bitsPerChannel = bitsPerChannel;
        self.converPackets = 0;
        
        self.converAudioDesc = [self createAudioBasicDescWithSampleRate:self.converSampleRate
                                                       channelPerSample:self.converChannel
                                                         bitsPerChannel:self.converBitsPerChannel
                                                            formatFlags:self.converFlags];
        
        [self setupAudioUnit];
    }];
}

- (void)stopRecord{
    if(_audioUnit) {
        //stop audio unit
        AudioOutputUnitStop(_audioUnit);
        AudioComponentInstanceDispose(_audioUnit);
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        _audioUnit = NULL;
    }
//    [self checkFloat32Pcm:self.pcmData];
    
    
    
    
    NSLog(@"[%s] save pcm to file", __FUNCTION__);
    
    
    NSString *originFileName = [NSString stringWithFormat:@"source_%u_%d_%d.wav",
                                self.sampleRate,
                                self.channels,
                                self.bitsPerChannel];
    UInt32 orginPackets = (UInt32)(self.pcmData.length / ((self.bitsPerChannel/8) * self.channels));
    
    NSString *converFileName = [NSString stringWithFormat:@"conver_%d_%d_%d.wav",
                                self.converSampleRate,
                                self.converChannel,
                                self.converBitsPerChannel];
    
    [AudioFileWrite write2FilePath:originFileName withAudioFormat:&_sourceAudioDesc audioData:self.pcmData audioPackets:orginPackets];
    [AudioFileWrite write2FilePath:converFileName withAudioFormat:&_converAudioDesc audioData:self.converPcmData audioPackets:self.converPackets];
    
    
    //save pcm data
//    uint8_t orginFormat = (self.mode == AudioCaptureModeFloat ? 0x03 : 0x01);
//    [AudioHelper savePCMData:self.pcmData
//                  sampleRate:self.sampleRate
//                  channelNum:self.channels
//              bitsPerChannel:self.bitsPerChannel
//                    byteRate:self.byteRate
//                  toFilename:@"source_pcm_44100_1_int16.wav"
//                  fileFormat:orginFormat];
//
//    uint8_t converFormat = (self.converMode == AudioCaptureModeFloat ? 0x03 : 0x01);
//    [AudioHelper savePCMData:self.converPcmData
//                  sampleRate:self.converSampleRate
//                  channelNum:self.converChannel
//              bitsPerChannel:self.converBitsPerChannel
//                    byteRate:self.converByterate
//                  toFilename:@"conver_pcm_48000_1_float32.wav"
//                  fileFormat:converFormat];
}

- (void)pause{
    if (self.paused) {
        return;
    }
    if(_audioUnit) {
        AudioOutputUnitStop(_audioUnit);
    }
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    self.paused = YES;
}

- (void)resume{
    if (!self.paused) {
        return;
    }
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
             withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth
                   error:nil];
    [session setActive:YES error:nil];
    
    if(_audioUnit) {
        AudioOutputUnitStart(_audioUnit);
    }
}

- (void)requestGrantedIfNeed:(void (^) (BOOL granted))callback{
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    if ([systemVersion compare:@"7.0" options:NSNumericSearch]) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session requestRecordPermission:callback];
    }else{
        callback(YES);
    }
}

- (void)setupAudioUnit{
    __weak typeof(self) weakSelf = self;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
             withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth
                   error:nil];
    [session setActive:YES error:nil];
    
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_Output;
    acd.componentSubType = kAudioUnitSubType_RemoteIO;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    acd.componentFlags = 0;
    acd.componentFlagsMask = 0;
    AudioComponent audioComponent = AudioComponentFindNext(NULL, &acd);
    AudioComponentInstanceNew(audioComponent, &_audioUnit);
    
    UInt32 flagOne = 1;
    AURenderCallbackStruct cb;
    cb.inputProcRefCon = (__bridge void * _Nullable)(weakSelf);
    cb.inputProc = handleInputBuffer;
    AudioStreamBasicDescription desc = [weakSelf createAudioStreamBasicDescription];
    self.sourceAudioDesc = desc;
    [self createAudioConver];
    
    
    NSLog(@"[%s] bytes per second=[%llu]", __FUNCTION__, (unsigned long long)(desc.mBytesPerFrame * desc.mSampleRate));
    //    _audioBufferSize = desc.mBytesPerFrame * desc.mSampleRate * 10 / 1000; //字节大小

    //setup audio unit property
    OSStatus result = 0;
    AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO,
                         kAudioUnitScope_Input, 1, &flagOne, sizeof(flagOne));
    
    result = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output, 1, &desc, sizeof(desc));
    if (result != noErr) {
        [AudioManager checkResult:result operation:__FUNCTION__];
    }
    
    AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_SetInputCallback,
                         kAudioUnitScope_Global, 1, &cb, sizeof(cb));
    
    //start audio unit
    AudioUnitInitialize(_audioUnit);
    AudioOutputUnitStart(_audioUnit);
}

- (void)createAudioConver{
    if (_audioConverterRef != NULL) {
        AudioConverterDispose(_audioConverterRef);
        _audioConverterRef = NULL;
    }
    OSStatus result = AudioConverterNew(&_sourceAudioDesc, &_converAudioDesc, &_audioConverterRef);
    if (result != noErr) {
        [AudioManager checkResult:result operation:__FUNCTION__];
        return;
    }
    [self descriptionForAudioFormat:_sourceAudioDesc];
    [self descriptionForAudioFormat:_converAudioDesc];
}

static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData){
    AudioManager *_thiz = (__bridge AudioManager*)(inRefCon);
    NSLog(@"[%s] _thiz->_channels=[%d] _thiz->_didLeftRightChannelInterLeaved=[%d]",
          __FUNCTION__, _thiz->_channels, _thiz->_didLeftRightChannelInterLeaved);
    AudioBufferList buffers;
    if (_thiz->_channels == 2 && _thiz->_didLeftRightChannelInterLeaved == NO) {
        AudioBuffer leftBuffer;
        leftBuffer.mData = NULL;
        leftBuffer.mDataByteSize = 0;
        leftBuffer.mNumberChannels = 1;

        AudioBuffer rightBuffer;
        rightBuffer.mData = NULL;
        rightBuffer.mDataByteSize = 0;
        rightBuffer.mNumberChannels = 1;

        AudioBufferList buffers;
        buffers.mNumberBuffers = 2;
        buffers.mBuffers[0] = leftBuffer;
        buffers.mBuffers[1] = rightBuffer;
    }else{
        AudioBuffer buffer;
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        buffer.mNumberChannels = _thiz.channels;
        
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0] = buffer;
    }
    
    OSStatus status = AudioUnitRender(_thiz->_audioUnit,
                                      ioActionFlags,
                                      inTimeStamp,
                                      inBusNumber,
                                      inNumberFrames,
                                      &buffers);
    if(status == noErr && buffers.mBuffers[0].mData != NULL) {
        if (!_thiz->_paused){
            unsigned int audioSize = buffers.mBuffers[0].mDataByteSize;
            
            static NSTimeInterval lastLog = 0;
            static unsigned int lastAudioSize = 0;
            NSTimeInterval currentLog = NSDate.date.timeIntervalSince1970 * 1000 * 1000;
            float call_interval = (currentLog - lastLog)/1000.f;
            if (lastLog > 0) {
                NSLog(@"[%s] inNumberFrames=[%u] call_interval=[%.2f] audioSize=[%u]",
                      __FUNCTION__,
                      inNumberFrames, call_interval, lastAudioSize);
            }
            lastLog = currentLog;
            lastAudioSize = audioSize;
            [_thiz onInputPCMData:buffers.mBuffers[0] sampleCount:inNumberFrames];
        }
    }else{
        [AudioManager checkResult:status operation:"handleInputBuffer"];
    }
    return status;
}

- (AudioStreamBasicDescription)createAudioStreamBasicDescription{    
    AudioFormatFlags formatFlags = kAudioFormatFlagIsPacked;
    int bitsPerChannel = 0;
    int bytePerSample = 0;
    
    
    switch (self.mode) {
        case AudioCaptureModeShortInt:
        {
            bitsPerChannel = sizeof(short int) * 8;
            formatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
            
            if (self.didLeftRightChannelInterLeaved == NO) {
                //NonInterLeaved
                bytePerSample = bitsPerChannel/8;
                self.byteRate = self.sampleRate * bytePerSample;
                formatFlags = formatFlags | kAudioFormatFlagIsNonInterleaved;
            }else{
                bytePerSample = bitsPerChannel/8 * self.channels;
                //If no set
                self.byteRate = self.sampleRate * bytePerSample;
            }
        }
            break;
        case AudioCaptureModeFloat:
        {
            formatFlags = kAudioFormatFlagIsFloat | kLinearPCMFormatFlagIsPacked;
            bitsPerChannel = sizeof(float) * 8;
            if (self.didLeftRightChannelInterLeaved == NO) {
                //NonInterLeaved
                bytePerSample = bitsPerChannel/8;
                self.byteRate = self.sampleRate * bytePerSample;
                formatFlags = formatFlags | kAudioFormatFlagIsNonInterleaved;
            }else{
                bytePerSample = bitsPerChannel/8 * self.channels;
                self.byteRate = self.sampleRate * bytePerSample;
            }
        }
            break;
        case AudioCaptureModeCanonical:
        {
            formatFlags = kAudioFormatFlagsAudioUnitCanonical;
            bytePerSample = sizeof(AudioUnitSampleType);
            bitsPerChannel = bytePerSample * 8;
        }
            break;
            
        default:
            break;
    }
    
    AudioStreamBasicDescription desc = {0};
    desc.mSampleRate = (Float64)self.sampleRate;
    desc.mFormatID = kAudioFormatLinearPCM;
    desc.mFormatFlags = formatFlags;
    desc.mChannelsPerFrame = self.channels;
    desc.mFramesPerPacket = 1;
    desc.mBitsPerChannel = bitsPerChannel;
    NSLog(@"[%s] mode=[%u] sampleRate=[%d] channels=[%d] interleaved=[%d]  bitsPerChannel=[%d] bytePerSample=[%d]",
          __FUNCTION__, (unsigned int)self.mode, self.sampleRate, self.channels, self.didLeftRightChannelInterLeaved, bitsPerChannel, bytePerSample);
    desc.mBytesPerFrame = bytePerSample;
    desc.mBytesPerPacket = desc.mBytesPerFrame * desc.mFramesPerPacket;
    
    
    
    return desc;
}

- (AudioStreamBasicDescription)createAudioBasicDescWithSampleRate:(NSUInteger)sampleRate
                                                 channelPerSample:(NSInteger)channelPerSample
                                                   bitsPerChannel:(NSUInteger)bitsPerChannel
                                                      formatFlags:(AudioFormatFlags)formatFlags{
    UInt32 bytePerSample = 0;
    if (self.didLeftRightChannelInterLeaved) {//左右声道交织在一起:LRLRLR
        bytePerSample = (UInt32)(channelPerSample * (bitsPerChannel/8));
    }else{
        bytePerSample = (UInt32)(bitsPerChannel/8);
    }
    NSLog(@"[%s] bitsPerChannel=[%u] bytePerSample=[%u]",
          __FUNCTION__, (UInt32)bitsPerChannel, bytePerSample);
    
    AudioStreamBasicDescription desc = {0};
    desc.mFormatID = kAudioFormatLinearPCM;
    desc.mSampleRate = (Float64)sampleRate;
    desc.mFormatFlags = formatFlags;
    desc.mChannelsPerFrame = (UInt32)channelPerSample;
    desc.mFramesPerPacket = 1;
    desc.mBitsPerChannel = (UInt32)bitsPerChannel;
    desc.mBytesPerFrame = bytePerSample;
    desc.mBytesPerPacket = desc.mBytesPerFrame * desc.mFramesPerPacket;
    return desc;
}

- (void)descriptionForAudioFormat:(AudioStreamBasicDescription) audioFormat{
    NSMutableString *description = [NSMutableString new];
    
    // From https://developer.apple.com/library/ios/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/ConstructingAudioUnitApps/ConstructingAudioUnitApps.html (Listing 2-8)
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (audioFormat.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    
    [description appendString:@"\n"];
    [description appendFormat:@"Sample Rate:         %10.0f \n",  audioFormat.mSampleRate];
    [description appendFormat:@"Format ID:           %10s \n",    formatIDString];
    [description appendFormat:@"Format Flags:        %10d \n",    (unsigned int)audioFormat.mFormatFlags];
    [description appendFormat:@"Bytes per Packet:    %10d \n",    (unsigned int)audioFormat.mBytesPerPacket];
    [description appendFormat:@"Frames per Packet:   %10d \n",    (unsigned int)audioFormat.mFramesPerPacket];
    [description appendFormat:@"Bytes per Frame:     %10d \n",    (unsigned int)audioFormat.mBytesPerFrame];
    [description appendFormat:@"Channels per Frame:  %10d \n",    (unsigned int)audioFormat.mChannelsPerFrame];
    [description appendFormat:@"Bits per Channel:    %10d \n",    (unsigned int)audioFormat.mBitsPerChannel];
    
    // Add flags (supposing standard flags).
    [description appendString:[self descriptionForStandardFlags:audioFormat.mFormatFlags]];
    
    NSLog(@"[%s] audioFormat=[%@]", __FUNCTION__, description);
}

- (NSString *)descriptionForStandardFlags:(UInt32) mFormatFlags{
    NSMutableString *description = [NSMutableString new];
    
    if (mFormatFlags & kAudioFormatFlagIsFloat)
    { [description appendString:@"kAudioFormatFlagIsFloat \n"]; }
    if (mFormatFlags & kAudioFormatFlagIsBigEndian)
    { [description appendString:@"kAudioFormatFlagIsBigEndian \n"]; }
    if (mFormatFlags & kAudioFormatFlagIsSignedInteger)
    { [description appendString:@"kAudioFormatFlagIsSignedInteger \n"]; }
    if (mFormatFlags & kAudioFormatFlagIsPacked)
    { [description appendString:@"kAudioFormatFlagIsPacked \n"]; }
    if (mFormatFlags & kAudioFormatFlagIsAlignedHigh)
    { [description appendString:@"kAudioFormatFlagIsAlignedHigh \n"]; }
    if (mFormatFlags & kAudioFormatFlagIsNonInterleaved)
    { [description appendString:@"kAudioFormatFlagIsNonInterleaved \n"]; }
    if (mFormatFlags & kAudioFormatFlagIsNonMixable)
    { [description appendString:@"kAudioFormatFlagIsNonMixable \n"]; }
    if (mFormatFlags & kAudioFormatFlagsAreAllClear)
    { [description appendString:@"kAudioFormatFlagsAreAllClear \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagIsFloat)
    { [description appendString:@"kLinearPCMFormatFlagIsFloat \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagIsBigEndian)
    { [description appendString:@"kLinearPCMFormatFlagIsBigEndian \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagIsSignedInteger)
    { [description appendString:@"kLinearPCMFormatFlagIsSignedInteger \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagIsPacked)
    { [description appendString:@"kLinearPCMFormatFlagIsPacked \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagIsAlignedHigh)
    { [description appendString:@"kLinearPCMFormatFlagIsAlignedHigh \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagIsNonInterleaved)
    { [description appendString:@"kLinearPCMFormatFlagIsNonInterleaved \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagIsNonMixable)
    { [description appendString:@"kLinearPCMFormatFlagIsNonMixable \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagsSampleFractionShift)
    { [description appendString:@"kLinearPCMFormatFlagsSampleFractionShift \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagsSampleFractionMask)
    { [description appendString:@"kLinearPCMFormatFlagsSampleFractionMask \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagsAreAllClear)
    { [description appendString:@"kLinearPCMFormatFlagsAreAllClear \n"]; }
    if (mFormatFlags & kAppleLosslessFormatFlag_16BitSourceData)
    { [description appendString:@"kAppleLosslessFormatFlag_16BitSourceData \n"]; }
    if (mFormatFlags & kAppleLosslessFormatFlag_20BitSourceData)
    { [description appendString:@"kAppleLosslessFormatFlag_20BitSourceData \n"]; }
    if (mFormatFlags & kAppleLosslessFormatFlag_24BitSourceData)
    { [description appendString:@"kAppleLosslessFormatFlag_24BitSourceData \n"]; }
    if (mFormatFlags & kAppleLosslessFormatFlag_32BitSourceData)
    { [description appendString:@"kAppleLosslessFormatFlag_32BitSourceData \n"]; }
    
    return [NSString stringWithString:description];
}

//- (void)queryHardwareAudioProperty{
//    Float64 hardwareSampleRate = 0;
//    UInt32 hardwareSampleRateSize = sizeof(hardwareSampleRate);
//    if (AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,
//                                &hardwareSampleRateSize,
//                                &hardwareSampleRate) == noErr) {
//        NSLog(@"[%s] hardwareSampleRate=[%d]", __FUNCTION__, hardwareSampleRate);
//    }
//
//    UInt32 hardwareNumberChannels = 0;
//    UInt32 hardwareChannelSize = sizeof(hardwareNumberChannels);
//    if (AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareInputNumberChannels,
//                                &hardwareChannelSize,
//                                &hardwareNumberChannels) == noErr) {
//        NSLog(@"[%s] hardwareNumberChannels=[%d]", __FUNCTION__, hardwareNumberChannels);
//    }
//}

- (void)checkFloat32Pcm:(uint8_t *)pcm length:(uint32_t)length{
    uint32_t step = 4;
    float minPcm = 0;
    float maxPcm = 0;
    for (NSUInteger index = 0; index < length; index+=step) {
        float *temp = (float *)(pcm+index);
        float lc = *temp;
        minPcm = MIN(lc, minPcm);
        maxPcm = MAX(lc, maxPcm);
//        if (small < minPcm) {
//            minPcm = small;
//        }
//        if (bigger > maxPcm) {
//            maxPcm = bigger;
//        }
    }
    NSLog(@"[%s] minPcm=[%f] maxPcm=[%f]", __FUNCTION__,  minPcm, maxPcm);
}

- (void)checkInt16Pcm:(uint8_t *)pcm length:(uint32_t)length{
    uint32_t step = 4;
    short minPcm = 0;
    short maxPcm = 0;
    for (NSUInteger index = 0; index < length; index+=step) {
        short *temp = (short *)(pcm+index);
        short lc = *temp;
        short rc = *(temp+1);
        short small = MIN(lc, rc);
        short bigger = MAX(lc, rc);
        if (small < minPcm) {
            minPcm = small;
        }
        if (bigger > maxPcm) {
            maxPcm = bigger;
        }
    }
    NSLog(@"[%s] minPcm=[%d] maxPcm=[%d]", __FUNCTION__,  minPcm, maxPcm);
}

- (void)onInputPCMData:(AudioBuffer)audioBuffer sampleCount:(NSUInteger)sampleCount{
    if (audioBuffer.mData == NULL
        || audioBuffer.mDataByteSize <= 0) {
        return;
    }
    [self.pcmData appendBytes:audioBuffer.mData length:audioBuffer.mDataByteSize];
    
    NSTimeInterval before = NSDate.date.timeIntervalSince1970 * 1000;
    self.totalSampleNum += sampleCount;
    self.currentSampleNum += sampleCount;
    if (self.currentSampleNum < self.converStep) {
        return;
    }
    UInt32 converPackets = (UInt32)floorf((self.converStep/(self.sampleRate*1.f)) * self.converSampleRate);
    UInt32 bytePersample = self.channels * (self.bitsPerChannel/8);
    //self.converAudioBufferMaxLength/(self.converChannel * self.converBitsPerChannel/8);
    NSLog(@"[%s] current thread=[%p] converPackets=[%u] bytePersample=[%u]",
          __FUNCTION__, NSThread.currentThread, converPackets, bytePersample);
    void *tempBuffer = (void *)self.pcmData.bytes;
    const void *originBuffer = (const void *)(tempBuffer+(self.converStep*self.converCount*bytePersample));
    NSUInteger originBufferLength = self.converStep * bytePersample;
    NSData *originAudioData = [NSData dataWithBytes:originBuffer length:originBufferLength];
    
    
    bzero(self.converAudioBufferPoint, self.converAudioBufferMaxLength);
    
    
    AudioBufferList outBuffer;
    outBuffer.mNumberBuffers = 1;
    outBuffer.mBuffers[0].mDataByteSize = self.converAudioBufferMaxLength;
    outBuffer.mBuffers[0].mData = self.converAudioBufferPoint;
    outBuffer.mBuffers[0].mNumberChannels = self.converChannel;
    
    
//    AudioStreamPacketDescription outputPacketsDesc[converPackets];

    NSArray *args = @[originAudioData];
    self.allowProvidaMoreAudioData = YES;
    OSStatus result = AudioConverterFillComplexBuffer(_audioConverterRef,
                                                      AudioConverterFiller,
                                                      (__bridge void *)(args),
                                                      &converPackets,
                                                      &outBuffer,
                                                      NULL);
    if (result == noErr || result == NO_MORE_AUDIO_DATA) {
        NSLog(@"[%s] conver pcm success origin converStep=[%u] converPackets=[%u] conversize=[%u]", __FUNCTION__,
              (unsigned int)self.converStep, converPackets, outBuffer.mBuffers[0].mDataByteSize);
        [self.converPcmData appendBytes:outBuffer.mBuffers[0].mData
                                 length:outBuffer.mBuffers[0].mDataByteSize];
        self.converPackets += converPackets;
    }else{
        [AudioManager checkResult:result operation:"onInputPCMData"];
    }

    self.currentSampleNum -= self.converStep;
    ++self.converCount;
    
    NSTimeInterval after = NSDate.date.timeIntervalSince1970 * 1000;
    NSLog(@"[%s] conver cost=[%u]", __FUNCTION__, (unsigned int)(after-before));
}

OSStatus AudioConverterFiller(AudioConverterRef inAudioConverter,
                              UInt32* ioNumberDataPackets,
                              AudioBufferList* ioData,
                              AudioStreamPacketDescription** outDataPacketDescription,
                              void* inUserData){
    NSLog(@"[%s] onInputPCMData current thread=[%p] ioNumberDataPackets=[%u]",
          __FUNCTION__, NSThread.currentThread, *ioNumberDataPackets);
    if (AudioManager.shareInstance.allowProvidaMoreAudioData == NO) {
        NSLog(@"[%s] onInputPCMData not more audio data", __FUNCTION__);
        ioData->mBuffers[0].mData = NULL;
        ioData->mBuffers[0].mDataByteSize = 0;
        ioData->mBuffers[0].mNumberChannels = AudioManager.shareInstance.channels;
        ioData->mNumberBuffers = 1;
        *ioNumberDataPackets = 0;
        return NO_MORE_AUDIO_DATA;//no more audio data wait for next loop
    }
    NSArray *args = (__bridge NSArray *)inUserData;
    NSData *originAudioData = args.count > 0 ? args[0] : nil;
    if(originAudioData == nil || originAudioData.length <= 0){
        return -100;
    }
    
    UInt32 bytePerSample = (AudioManager.shareInstance.bitsPerChannel/8) * AudioManager.shareInstance.channels;
    *ioNumberDataPackets = (UInt32)originAudioData.length / bytePerSample;
    NSLog(@"[%s] onInputPCMData ioNumberDataPackets=[%u] audiodataLength=[%u] bytePerSample=[%u]", __FUNCTION__,
          *ioNumberDataPackets, (UInt32)originAudioData.length, bytePerSample);
    
    ioData->mBuffers[0].mData = (void *)originAudioData.bytes;
    ioData->mBuffers[0].mDataByteSize = (UInt32)originAudioData.length;
    ioData->mBuffers[0].mNumberChannels = AudioManager.shareInstance.channels;
    ioData->mNumberBuffers = 1;
    
    if (outDataPacketDescription) {
        NSLog(@"[%s] outDataPacketDescription is not null", __FUNCTION__);
        AudioStreamPacketDescription temp = **outDataPacketDescription;
        temp.mDataByteSize = (UInt32)originAudioData.length;
        temp.mStartOffset = 0;
        temp.mVariableFramesInPacket = 1;
    }
    AudioManager.shareInstance.allowProvidaMoreAudioData = NO;
    return noErr;
}

+ (void)checkResult:(OSStatus)result operation:(const char *)operation{
    if (result == noErr) return;
    char errorString[20];
    // see if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(result);
    if (isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4]))
    {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(errorString, "%d", (int)result);
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
}

@end
