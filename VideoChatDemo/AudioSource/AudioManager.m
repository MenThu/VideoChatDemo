//
//  AudioManager.m
//  VideoChatDemo
//
//  Created by menthu on 2022/8/23.
//  Copyright © 2022 menthu. All rights reserved.
//

#import "AudioManager.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AudioHelper.h"

@interface AudioManager ()

@property (nonatomic, strong) NSMutableData *pcmData;

@property (nonatomic, assign) unsigned int sampleRate;
@property (nonatomic, assign) int channels;
@property (nonatomic, assign) int sampleBits;

@property (nonatomic, assign) AudioComponentInstance audioUnit;

@property (nonatomic, assign) BOOL paused;

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
    }
    return self;
}

- (void)startRecordWithSampleRate:(unsigned int)sampleRate channels:(int)channels sampleBits:(int)sampleBits{
    [self requestGrantedIfNeed:^(BOOL granted) {
        self.sampleRate = sampleRate;
        self.channels = channels;
        self.sampleBits = sampleBits;
        
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
    
    NSLog(@"[%s] save pcm to file", __FUNCTION__);
    //save pcm data
    NSUInteger pcmDataLength = self.pcmData.length;
    [AudioHelper savePCMData:self.pcmData
                  sampleRate:self.sampleRate
                  channelNum:self.channels
                  toFilename:@"TEST_PCM.wav"];
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
    NSLog(@"[%s] bytes per second=[%llu]", __FUNCTION__, (unsigned long long)(desc.mBytesPerFrame * desc.mSampleRate));
//    _audioBufferSize = desc.mBytesPerFrame * desc.mSampleRate * 10 / 1000; //字节大小
    
    //setup audio unit property
    AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO,
                         kAudioUnitScope_Input, 1, &flagOne, sizeof(flagOne));
    AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output, 1, &desc, sizeof(desc));
    AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_SetInputCallback,
                         kAudioUnitScope_Global, 1, &cb, sizeof(cb));
    
    //start audio unit
    AudioUnitInitialize(_audioUnit);
    AudioOutputUnitStart(_audioUnit);
}

static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData){
    AudioManager *_thiz = (__bridge AudioManager*)(inRefCon);
    
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
        if (!_thiz->_paused){
            uint8_t* audioBuffer = (uint8_t*)buffers.mBuffers[0].mData;
            unsigned int audioSize = buffers.mBuffers[0].mDataByteSize;
            
            static NSTimeInterval lastLog = 0;
            static unsigned int lastAudioSize = 0;
            NSTimeInterval currentLog = NSDate.date.timeIntervalSince1970 * 1000 * 1000;
            float call_interval = (currentLog - lastLog)/1000.f;
            if (lastLog > 0) {
                NSLog(@"[%s] call_interval=[%.2f] audioSize=[%u]", __FUNCTION__, call_interval, lastAudioSize);
            }
            lastLog = currentLog;
            lastAudioSize = audioSize;
            [_thiz->_pcmData appendData:[NSData dataWithBytes:audioBuffer length:audioSize]];
            
        }
    }
    return status;
}

- (AudioStreamBasicDescription)createAudioStreamBasicDescription{
    AudioStreamBasicDescription desc = {0};
    desc.mSampleRate = (Float64)self.sampleRate;
    desc.mFormatID = kAudioFormatLinearPCM;
    desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    desc.mChannelsPerFrame = self.channels;
    desc.mFramesPerPacket = 1;
    desc.mBitsPerChannel = 16;
    int short_int_size = sizeof(short int);
    NSLog(@"[%s] short_int_size=[%d]", __FUNCTION__, short_int_size);
    desc.mBytesPerFrame = (desc.mChannelsPerFrame * desc.mBitsPerChannel)/8;
    desc.mBytesPerPacket = desc.mBytesPerFrame * desc.mFramesPerPacket;
    
    return desc;
}

@end
