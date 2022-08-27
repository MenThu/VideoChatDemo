//
//  AudioSource.m
//  VideoChatDemo
//
//  Created by menthu on 2022/8/27.
//  Copyright © 2022 menthu. All rights reserved.
//

#import "AudioSource.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface AudioSource ()

@property (nonatomic, assign) UInt32 sampleRate;
@property (nonatomic, assign) UInt32 channels;
@property (nonatomic, assign) AudioFormatFlags audioFormatFlags;
@property (nonatomic, strong) NSMutableData *pcmData;
@property (nonatomic, assign) AudioComponentInstance audioUnit;
@property (nonatomic, assign, readwrite) AudioStreamBasicDescription recordAudioDesc;
@property (nonatomic, assign, getter=isPaused) BOOL paused;
@property (nonatomic, copy) AudioDataCallBack callback;

@end

@implementation AudioSource

#pragma mark - LifeCycle
- (instancetype)initWithSampleRate:(Float64)sampleRate
                          channels:(UInt32)channels
                  audioFormatFlags:(AudioFormatFlags)audioFormatFlags
                          callback:(AudioDataCallBack)callback{
    if (self = [super init]) {
        self.sampleRate = sampleRate;
        self.channels = channels;
        self.audioFormatFlags = audioFormatFlags;
        self.callback = callback;
    }
    return self;
}

- (void)dealloc{
    [self stopRecord];
}

#pragma mark - Public方法
- (void)startRecord:(void (^) (BOOL succ))callback{
    __weak typeof(self) weakSelf = self;
    [self requestAuthorization:^(BOOL didAuthorized) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (didAuthorized == NO) {
            callback(NO);
        }else{
            [strongSelf setupAudioUnit];
            callback(YES);
            AudioOutputUnitStart(strongSelf->_audioUnit);
        }
    }];
}

- (void)pause{
    if(_audioUnit) {
        AudioOutputUnitStop(_audioUnit);
    }
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)resume{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
             withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth
                   error:nil];
    [session setActive:YES error:nil];
    
    if(_audioUnit) {
        AudioOutputUnitStart(_audioUnit);
    }
}

- (void)stopRecord{
    if(_audioUnit) {
        //stop audio unit
        AudioOutputUnitStop(_audioUnit);
        AudioComponentInstanceDispose(_audioUnit);
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        _audioUnit = NULL;
    }
}

#pragma mark - AudioUnit相关
- (void)requestAuthorization:(void (^) (BOOL didAuthorized))callback{
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    if ([systemVersion compare:@"7.0" options:NSNumericSearch]) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session requestRecordPermission:callback];
    }else{
        callback(YES);
    }
}

static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData);
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
    OSStatus result = AudioComponentInstanceNew(audioComponent, &_audioUnit);
    if (result != noErr) {
        LoggerInfo(kLoggerLevel, @"create audio unit failed=[%d]", result);
        return;
    }
    UInt32 bitsPerChannel = 0;
    if (self.audioFormatFlags & kAudioFormatFlagIsFloat) {
        bitsPerChannel = sizeof(float) * 8;
    }else if (self.audioFormatFlags & kAudioFormatFlagIsSignedInteger){
        bitsPerChannel = sizeof(short) * 8;
    }
    NSAssert(bitsPerChannel != 0, @"AudioFormatFlags is error");
    AudioStreamBasicDescription desc = [AudioExt createAudioBasicDescWithSampleRate:(Float64)self.sampleRate
                                                                   channelPerSample:self.channels
                                                                     bitsPerChannel:bitsPerChannel
                                                                            AudioID:kAudioFormatLinearPCM
                                                                        formatFlags:self.audioFormatFlags];
    UInt32 flagOne = 1;
    AURenderCallbackStruct cb;
    cb.inputProcRefCon = (__bridge void * _Nullable)(weakSelf);
    cb.inputProc = handleInputBuffer;
    self.recordAudioDesc = desc;
    
    //setup audio unit property
    result = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO,
                         kAudioUnitScope_Input, 1, &flagOne, sizeof(flagOne));
    
    result = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output, 1, &desc, sizeof(desc));
    if (result != noErr) {
        [AudioExt checkResult:result operation:__FUNCTION__];
        return;
    }
    
    AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_SetInputCallback,
                         kAudioUnitScope_Global, 1, &cb, sizeof(cb));
    
    //start audio unit
    AudioUnitInitialize(_audioUnit);
}

static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData){
    AudioSource *_thiz = (__bridge AudioSource*)(inRefCon);
    if (_thiz.isPaused) {
        return noErr;
    }
    
    AudioBuffer buffer;
    buffer.mData = NULL;
    buffer.mDataByteSize = 0;
    buffer.mNumberChannels = _thiz.channels;
    
    AudioBufferList buffers;
    buffers.mNumberBuffers = 1;
    buffers.mBuffers[0] = buffer;
    
    OSStatus status = AudioUnitRender(_thiz->_audioUnit,
                                      ioActionFlags,
                                      inTimeStamp,
                                      inBusNumber,
                                      inNumberFrames,
                                      &buffers);
    if(status == noErr && buffers.mBuffers[0].mData != NULL) {
//        {
//            unsigned int audioSize = buffers.mBuffers[0].mDataByteSize;
//            static NSTimeInterval lastLog = 0;
//            static unsigned int lastAudioSize = 0;
//            NSTimeInterval currentLog = NSDate.date.timeIntervalSince1970 * 1000 * 1000;
//            float call_interval = (currentLog - lastLog)/1000.f;
//            if (lastLog > 0) {
//                LoggerInfo(kLoggerLevel, @"inNumberFrames=[%u] call_interval=[%.2f] audioSize=[%u]",
//                           inNumberFrames, call_interval, lastAudioSize);
//            }
//            lastLog = currentLog;
//            lastAudioSize = audioSize;
//        }
        _thiz->_callback(buffers.mBuffers[0], inNumberFrames);
    }else{
        [AudioExt checkResult:status operation:"handleInputBuffer"];
    }
    return status;
}

@end
