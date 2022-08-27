//
//  AudioConver.m
//  VideoChatDemo
//
//  Created by menthu on 2022/8/27.
//  Copyright © 2022 menthu. All rights reserved.
//

#import "AudioProcesser.h"
#import "AudioExt.h"

#define NO_MORE_AUDIO_DATA -100

@interface AudioProcesser ()

@property (nonatomic, assign) UInt32 originSamplerRate;
@property (nonatomic, assign) UInt32 originChannels;
@property (nonatomic, assign) UInt32 originAudioFormatFlags;
@property (nonatomic, assign) AudioStreamBasicDescription originAudioDesc;
@property (nonatomic, assign) UInt32 originSampleStep;

@property (nonatomic, assign) UInt32 converSampleRate;
@property (nonatomic, assign) UInt32 converChannels;
@property (nonatomic, assign) UInt32 converAudioFormatFlags;
@property (nonatomic, assign) UInt32 converSampleStep;
@property (nonatomic, copy) ConverAudioCallBack converAudioCallback;
@property (nonatomic, assign) AudioStreamBasicDescription converAudioDesc;
@property (nonatomic, assign) AudioConverterRef audioConverterRef;

@property (nonatomic, assign) void *converAudioBuffer;
@property (nonatomic, assign) UInt32 converAudioLength;

@property (nonatomic, assign) BOOL shoudAudioConverFuncProvideMoreAudioData;
@property (nonatomic, weak) NSThread *converAudioDataThread;

@end

@implementation AudioProcesser

#pragma mark - LifeCycle
- (instancetype)initWithOriginSampleRate:(Float64)sampleRate
                          originChannels:(UInt32)channels
                  originAudioFormatFlags:(AudioFormatFlags)audioFormatFlags
                   originAudioStreamDesc:(AudioStreamBasicDescription)originAudioDesc
                        originSampleStep:(UInt32)originSampleStep
                        converSampleRate:(Float64)converSampleRate
                          converChannels:(UInt32)converChannels
                  converAudioFormatFlags:(AudioFormatFlags)converAudioFormatFlags
                          converCallback:(ConverAudioCallBack)converCallback{
    if (self = [super init]) {
        self.originSamplerRate = sampleRate;
        self.originChannels = channels;
        self.originAudioFormatFlags = audioFormatFlags;
        self.originAudioDesc = originAudioDesc;
        self.originSampleStep = originSampleStep;
        
        self.converSampleRate = converSampleRate;
        self.converChannels = converChannels;
        self.converAudioFormatFlags = converAudioFormatFlags;
        UInt32 bitsPerChannel = 0;
        if (converAudioFormatFlags & kAudioFormatFlagIsSignedInteger) {
            bitsPerChannel = sizeof(short) * 8;
        }else if (converAudioFormatFlags & kAudioFormatFlagIsFloat){
            bitsPerChannel = sizeof(float) * 8;
        }
        NSAssert(bitsPerChannel != 0, @"converAudioFormatFlags invalid");
        AudioStreamBasicDescription converAudioDesc = [AudioExt createAudioBasicDescWithSampleRate:converSampleRate
                                                                                  channelPerSample:converChannels
                                                                                    bitsPerChannel:bitsPerChannel
                                                                                           AudioID:kAudioFormatLinearPCM
                                                                                       formatFlags:converAudioFormatFlags];
        self.converAudioDesc = converAudioDesc;
        self.converSampleStep = (UInt32)floorf((originSampleStep / (float)sampleRate) * originSampleStep);
        self.converAudioLength = self.converSampleStep * converChannels * (bitsPerChannel/8);
        self.converAudioBuffer = malloc(self.converAudioLength);
        self.converAudioCallback = converCallback;
        self.shoudAudioConverFuncProvideMoreAudioData = NO;
        
        [self setupAudioConver];
    }
    return self;
}

- (void)dealloc{
    [self releaseAudioConverIfNeed];
    [self releaseAudioBufferIfNeed];
}

#pragma mark - Public
- (void)inputOrignAudioData:(void *)audioBuffer audioLength:(NSUInteger)audioLength numPackets:(UInt32)numPackets{
    NSAssert(numPackets == self.originSampleStep, @"caller should adjust audio step before this func");
    bzero(self.converAudioBuffer, self.converAudioLength);
    AudioBufferList outBuffer;
    outBuffer.mNumberBuffers = 1;
    outBuffer.mBuffers[0].mDataByteSize = self.converAudioLength;
    outBuffer.mBuffers[0].mData = self.converAudioBuffer;
    outBuffer.mBuffers[0].mNumberChannels = self.converChannels;
    
    self.shoudAudioConverFuncProvideMoreAudioData = YES;
    self.converAudioDataThread = NSThread.currentThread;
    
    UInt32 converPackets = self.converSampleStep;
    
    NSData *originAudioData = [NSData dataWithBytes:audioBuffer length:audioLength];
    NSArray *args = @[self, originAudioData];
    
    OSStatus result = AudioConverterFillComplexBuffer(_audioConverterRef,
                                                      AudioConverterFiller,
                                                      (__bridge void *)(args),
                                                      &converPackets,
                                                      &outBuffer,
                                                      NULL);
    if (result == noErr || result == NO_MORE_AUDIO_DATA) {
        LoggerInfo(kLoggerLevel, @"request=[%u] actual=[%u] buffersize=[%u]",
                   self.converSampleStep, converPackets, outBuffer.mBuffers[0].mDataByteSize);
        self.converAudioCallback(outBuffer.mBuffers[0], converPackets);
    }else{
        [AudioExt checkResult:result operation:"onInputPCMData"];
    }
}

#pragma mark - AudioConver相关
- (void)setupAudioConver{
    [self releaseAudioConverIfNeed];
    OSStatus result = AudioConverterNew(&_originAudioDesc, &_converAudioDesc, &_audioConverterRef);
    if (result != noErr
        || _audioConverterRef == NULL) {
        [AudioExt checkResult:result operation:__FUNCTION__];
        return;
    }
}

- (void)releaseAudioConverIfNeed{
    if (self.audioConverterRef != NULL) {
        AudioConverterDispose(self.audioConverterRef);
        self.audioConverterRef = NULL;
    }
}

- (void)releaseAudioBufferIfNeed{
    if (self.converAudioBuffer != NULL) {
        free(self.converAudioBuffer);
        self.converAudioBuffer = NULL;
    }
}

static OSStatus AudioConverterFiller(AudioConverterRef inAudioConverter,
                              UInt32* ioNumberDataPackets,
                              AudioBufferList* ioData,
                              AudioStreamPacketDescription** outDataPacketDescription,
                              void* inUserData){
    NSArray *args = (__bridge NSArray *)inUserData;
    AudioProcesser *audioConver = (AudioProcesser *)args[0];
    if (NSThread.currentThread != audioConver.converAudioDataThread) {
        LoggerInfo(kLoggerLevel, @"caller thread and callback thread is not the same, this may cause data issue");
        return -1;
    }
    if (audioConver.shoudAudioConverFuncProvideMoreAudioData == NO) {
        LoggerInfo(kLoggerLevel, @"not more audio data");
        *ioNumberDataPackets = 0;
        return NO_MORE_AUDIO_DATA;//no more audio data wait for next loop
    }
    
    NSData *originAudioData = args.count > 1 ? args[1] : nil;
    if(originAudioData == nil || originAudioData.length <= 0){
        return NO_MORE_AUDIO_DATA;
    }
    *ioNumberDataPackets = audioConver.originSampleStep;
    
    ioData->mBuffers[0].mData = (void *)originAudioData.bytes;
    ioData->mBuffers[0].mDataByteSize = (UInt32)originAudioData.length;
    ioData->mBuffers[0].mNumberChannels = audioConver.originChannels;
    ioData->mNumberBuffers = 1;
    
    if (outDataPacketDescription) {
        LoggerInfo(kLoggerLevel, @"outDataPacketDescription is not null");
        AudioStreamPacketDescription temp = **outDataPacketDescription;
        temp.mDataByteSize = (UInt32)originAudioData.length;
        temp.mStartOffset = 0;
        temp.mVariableFramesInPacket = 1;
    }
    audioConver.shoudAudioConverFuncProvideMoreAudioData = NO;
    return noErr;
}


@end
