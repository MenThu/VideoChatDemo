//
//  AudioController.m
//  VideoChatDemo
//
//  Created by menthu on 2022/8/23.
//  Copyright © 2022 menthu. All rights reserved.
//

#import "AudioController.h"
#import "AudioManager.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioSource.h"
#import "AudioFileWrite.h"
#import "AudioProcesser.h"
#import <AudioEffectSDK/audioeffect.h>

@interface AudioController ()

//采集
@property (nonatomic, strong) AudioSource *micAudioSource;
@property (nonatomic, strong) NSMutableData *recordAudioPcm;
@property (nonatomic, assign) Float64 recordSampleRate;
@property (nonatomic, assign) UInt32 recordChannels;
@property (nonatomic, assign) UInt32 recordBitsPerChannel;
@property (nonatomic, assign) UInt32 recordBytePerSample;
@property (nonatomic, assign) BOOL recordInt;
@property (nonatomic, assign) UInt32 currentSample;
@property (nonatomic, assign) UInt64 totalSample;
@property (nonatomic, assign) UInt32 converCount;

//转码
@property (nonatomic, assign) UInt32 originSampleStep;
@property (nonatomic, assign) UInt32 converSampleRate;
@property (nonatomic, assign) UInt32 converChannels;
@property (nonatomic, assign) BOOL converInt;
@property (nonatomic, strong) AudioProcesser *audioConver;
@property (nonatomic, strong) NSMutableData *converPcmData;
@property (nonatomic, assign) UInt64 converPackets;
@property (nonatomic, assign) UInt32 converBytePerSample;

//混响
@property (nonatomic, strong) NSMutableData *audioEffectBuffer;
@property (nonatomic, assign) UInt32 processStep;
@property (nonatomic, assign) UInt32 processCount;
@property (nonatomic, assign) UInt32 currentProcessSampleCount;
@property (nonatomic, assign) float *leftChannel;
@property (nonatomic, assign) float *rightChannel;
@property (nonatomic, assign) float *afterAudioLeftChannel;
@property (nonatomic, assign) float *afterAudioRightChannel;
@property (nonatomic, assign) float *leftRightAudioBuffer;

//还原
@property (nonatomic, strong) AudioProcesser *finalAudioConver;
@property (nonatomic, assign) UInt32 currentAudioEffectCount;
@property (nonatomic, assign) UInt32 finalConverCount;
@property (nonatomic, strong) NSMutableData *finalPcmData;
@property (nonatomic, assign) UInt64 finalConverPackets;

//音频属性描述
@property (nonatomic, assign) AudioStreamBasicDescription micAudioDesc;
@property (nonatomic, assign) AudioStreamBasicDescription converAudioDesc;

@end

@implementation AudioController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    LoggerInfo(kLoggerLevel, @"init mic aduio source");
    [self setupMicSource];
    [self setupAudioEffect];
}

#pragma mark - 采集
- (void)setupMicSource{
    __weak typeof(self) weakSelf = self;
    self.recordAudioPcm = [NSMutableData data];
    self.recordSampleRate = 44100;
    self.recordChannels = 1;
    self.recordInt = YES;
    self.recordBitsPerChannel = 0;
    AudioFormatFlags audioFlags = kAudioFormatFlagIsPacked;
    if (self.recordInt) {
        audioFlags |= kAudioFormatFlagIsSignedInteger;
        self.recordBitsPerChannel = sizeof(short) * 8;
    }else{
        audioFlags |= kAudioFormatFlagIsFloat;
        self.recordBitsPerChannel = sizeof(float) * 8;
    }
    self.recordBytePerSample = self.recordChannels * (self.recordBitsPerChannel/8);
    AudioSource *micAudioSource = [[AudioSource alloc] initWithSampleRate:self.recordSampleRate
                                                                 channels:self.recordChannels
                                                         audioFormatFlags:audioFlags
                                                                 callback:^(AudioBuffer audioBuffer, UInt32 audioPackets) {
        [weakSelf recordAudioData:audioBuffer audioPackets:audioPackets];
    }];
    self.micAudioSource = micAudioSource;
}

- (void)recordAudioData:(AudioBuffer)buffer audioPackets:(UInt32)audioPackets{
    if (buffer.mData == NULL
        || buffer.mDataByteSize <= 0) {
        LoggerInfo(kLoggerLevel, @"callback audio data error");
        return;
    }
    LoggerInfo(kLoggerLevel, @"audio mic source product=[%u]", audioPackets);
    [self.recordAudioPcm appendBytes:buffer.mData length:buffer.mDataByteSize];
    self.totalSample += audioPackets;
    [self.audioConver processAudioBuffer:buffer.mData audioLength:buffer.mDataByteSize audioPackets:audioPackets];
}

#pragma mark - 混响
- (void)setupAudioEffect{
    self.audioEffectBuffer = [NSMutableData data];
    self.processStep = 64;
    self.processCount = 0;
    self.currentProcessSampleCount = 0;
    audioEffectInit();
    audioEffectSet(AUDIO_EFFECT_CONCERT);
    
    self.leftChannel = malloc(self.processStep * 4);
    self.rightChannel = malloc(self.processStep * 4);
    self.afterAudioLeftChannel = malloc(self.processStep * 4);
    self.afterAudioRightChannel = malloc(self.processStep * 4);
    self.leftRightAudioBuffer = malloc(self.processStep * 2 * 4);
}

- (void)audioEffect:(UInt32)converPackets{
    self.currentProcessSampleCount += converPackets;
    UInt32 lengthPerStep = self.processStep * self.converBytePerSample;
    NSMutableData *audioEffectData = [NSMutableData data];
    while (self.currentProcessSampleCount / self.processStep >= 1) {
        void *tempData = (void *)self.converPcmData.bytes;
        tempData = tempData + (self.processCount * lengthPerStep);
        float *floatTempData = (float *)tempData;
        bzero(self.leftChannel, self.processStep*4);
        bzero(self.rightChannel, self.processStep*4);
        bzero(self.afterAudioLeftChannel, self.processStep*4);
        bzero(self.afterAudioRightChannel, self.processStep*4);
        bzero(self.leftRightAudioBuffer, self.processStep*8);
        if (self.converChannels == 2) {
            for (int i = 0; i < self.processStep; i ++) {
                *(self.leftChannel+i) = *(floatTempData+i*2);
                *(self.rightChannel+i) = *(floatTempData+i*2+1);
            }
            audioEffectProcess(self.leftChannel, self.rightChannel,
                               self.afterAudioLeftChannel, self.afterAudioRightChannel);
            for (int i = 0; i < self.processStep; i ++) {
                *(self.leftRightAudioBuffer+i*2) = *(self.afterAudioLeftChannel+i);
                *(self.leftRightAudioBuffer+i*2+1) = *(self.afterAudioRightChannel+i);
            }
            [audioEffectData appendBytes:self.leftRightAudioBuffer length:self.processStep*8];
            [self.audioEffectBuffer appendBytes:self.leftRightAudioBuffer length:self.processStep*8];
        }else{
            for (int i = 0; i < self.processStep; i ++) {
                *(self.leftChannel+i) = *(floatTempData+i);
            }
            audioEffectProcess(self.leftChannel, self.rightChannel,
                               self.afterAudioLeftChannel, self.afterAudioRightChannel);
            [audioEffectData appendBytes:self.afterAudioLeftChannel length:self.processStep*4];
            [self.audioEffectBuffer appendBytes:self.afterAudioLeftChannel length:self.processStep*4];
        }
        self.processCount++;
        self.currentAudioEffectCount += self.processStep;
        self.currentProcessSampleCount -= self.processStep;
    }
    if ((UInt32)audioEffectData.length % self.converBytePerSample != 0) {
        NSAssert(NO, @"data error");
        return;
    }
    UInt32 audioPackets = (UInt32)audioEffectData.length / self.converBytePerSample;
    [self.finalAudioConver processAudioBuffer:(void *)audioEffectData.bytes
                                  audioLength:audioEffectData.length
                                 audioPackets:audioPackets];
}

- (void)releaseAudioEffect{
    if (self.leftChannel != NULL) {
        free(self.leftChannel);
        self.leftChannel = NULL;
    }
    
    if (self.rightChannel != NULL) {
        free(self.rightChannel);
        self.rightChannel = NULL;
    }
    
    if (self.afterAudioLeftChannel != NULL) {
        free(self.afterAudioLeftChannel);
        self.afterAudioLeftChannel = NULL;
    }
    
    if (self.afterAudioRightChannel != NULL) {
        free(self.afterAudioRightChannel);
        self.afterAudioRightChannel = NULL;
    }
    
    if (self.leftRightAudioBuffer != NULL) {
        free(self.leftRightAudioBuffer);
        self.leftRightAudioBuffer = NULL;
    }
}

#pragma mark - 转码
//转码到48K
- (void)setupAudioConver{
    __weak typeof(self) weakSelf = self;
    self.converCount = 0;
    self.originSampleStep = 1024 * 2;
    Float64 converSampleRate = 48000;
    UInt32 converChannels = 2;
    self.converInt = NO;
    self.converSampleRate = converSampleRate;
    self.converChannels = converChannels;
    UInt32 converBitsPerChannel = 0;
    AudioFormatFlags converAudioFlags = kAudioFormatFlagIsPacked;
    if (self.converInt) {
        converAudioFlags |= kAudioFormatFlagIsSignedInteger;
        self.converBytePerSample = sizeof(short) * self.converChannels;
        converBitsPerChannel = sizeof(short) * 8;
    }else{
        converAudioFlags |= kAudioFormatFlagIsFloat;
        self.converBytePerSample = sizeof(float) * self.converChannels;
        converBitsPerChannel = sizeof(float) * 8;
    }
    
    
    self.converPcmData = [NSMutableData data];
    AudioStreamBasicDescription targetAudioDesc = [AudioExt createAudioBasicDescWithSampleRate:self.converSampleRate
                                                                            channelPerSample:self.converChannels
                                                                              bitsPerChannel:converBitsPerChannel
                                                                                     AudioID:kAudioFormatLinearPCM
                                                                                 formatFlags:converAudioFlags];
    self.converAudioDesc = targetAudioDesc;
    
    DYAudioProperty *sourcePropery = [[DYAudioProperty alloc] init];
    sourcePropery.audioDesc = self.micAudioSource.recordAudioDesc;
    sourcePropery.roundup = YES;
    sourcePropery.bytePerSample = self.recordChannels * (self.recordBitsPerChannel/8);
    
    DYAudioProperty *targetPropery = [[DYAudioProperty alloc] init];
    targetPropery.audioDesc = targetAudioDesc;
    targetPropery.roundup = YES;
    targetPropery.bytePerSample = self.converBytePerSample;
    
    
    
    self.audioConver = [[AudioProcesser alloc] initWithSourceAudioProperty:sourcePropery
                                                       targetAudioProperty:targetPropery
                                                          converSampleStep:self.originSampleStep
                                                            converCallback:^(AudioBuffer converAudioBuffer,
                                                                             UInt32 converPackets) {
        [weakSelf converAudioData:converAudioBuffer converPackets:converPackets];
    }];
    
    
    
    [self setupFinalAudioConver];
}

- (void)converAudioData:(AudioBuffer)audioBuffer converPackets:(UInt32)converPackets{
    [self.converPcmData appendBytes:audioBuffer.mData
                             length:audioBuffer.mDataByteSize];
    self.converPackets += converPackets;
    [self audioEffect:converPackets];
}


//对经过混响的音频数据进行转码，转码配置和采集配置一致
- (void)setupFinalAudioConver{
    __weak typeof(self) weakSelf = self;
    self.finalPcmData = [NSMutableData data];
    
    UInt32 step = 2048 * 48 / 44.1;
    
    DYAudioProperty *sourcePropery = [[DYAudioProperty alloc] init];
    sourcePropery.audioDesc = self.converAudioDesc;
    sourcePropery.bytePerSample = self.converAudioDesc.mChannelsPerFrame * (self.converAudioDesc.mBitsPerChannel/8);
    
    DYAudioProperty *targetPropery = [[DYAudioProperty alloc] init];
    targetPropery.audioDesc = self.micAudioSource.recordAudioDesc;
    targetPropery.roundup = YES;
    targetPropery.bytePerSample = (self.recordBitsPerChannel/8)*self.micAudioSource.recordAudioDesc.mChannelsPerFrame;
    
    self.finalAudioConver = [[AudioProcesser alloc] initWithSourceAudioProperty:sourcePropery
                                                            targetAudioProperty:targetPropery
                                                               converSampleStep:step
                                                                 converCallback:^(AudioBuffer converAudioBuffer,
                                                                                  UInt32 converPackets) {
        [weakSelf finalAudioData:converAudioBuffer converPackets:converPackets];
    }];
}

- (void)finalAudioData:(AudioBuffer)audioBuffer converPackets:(UInt32)converPackets{
    [self.finalPcmData appendBytes:audioBuffer.mData
                            length:audioBuffer.mDataByteSize];
    self.finalConverPackets += converPackets;
}

#pragma mark - 点击事件
- (IBAction)onStartClick:(UIButton *)sender {
    [self.micAudioSource startRecord:^(BOOL succ) {
        if (!succ) {
            LoggerInfo(kLoggerLevel, @"startRecord error");
        }else{
            [self setupAudioConver];
        }
    }];
}


- (IBAction)onStopClick:(UIButton *)sender {
    NSLog(@"%s", __FUNCTION__);
    
    [self.micAudioSource stopRecord];
    
    NSString *audioFlags = self.recordInt ? @"int16" : @"float32";
    NSString *originFileName = [NSString stringWithFormat:@"record_%u_%u_%@.wav",
                                (UInt32)self.recordSampleRate, self.recordChannels,audioFlags];
    AudioStreamBasicDescription recordAsbd = self.micAudioSource.recordAudioDesc;
    [AudioFileWrite write2FilePath:originFileName
                   withAudioFormat:&recordAsbd
                         audioData:self.recordAudioPcm
                      audioPackets:(UInt32)self.totalSample];
    
    
    NSString *converAudioFlags = self.converInt ? @"int16" : @"float32";
    NSString *converFileName = [NSString stringWithFormat:@"conver_%u_%u_%@.wav",
                                (UInt32)self.converSampleRate, self.converChannels, converAudioFlags];
    AudioStreamBasicDescription converAudioDesc = self.converAudioDesc;
    [AudioFileWrite write2FilePath:converFileName
                   withAudioFormat:&converAudioDesc
                         audioData:self.converPcmData
                      audioPackets:(UInt32)self.converPackets];
    
    NSString *effectAudioFileName = [NSString stringWithFormat:@"effect_%u_%u_%@.wav",
                                     (UInt32)self.converSampleRate, self.converChannels, converAudioFlags];
    UInt64 effectPackets = self.converPackets - (self.converPackets % self.processStep);
    [AudioFileWrite write2FilePath:effectAudioFileName
                   withAudioFormat:&converAudioDesc
                         audioData:self.audioEffectBuffer
                      audioPackets:(UInt32)effectPackets];

    NSString *finalAudioFileName = [NSString stringWithFormat:@"final_%u_%u_%@.wav",
                                     (UInt32)self.recordSampleRate, self.recordChannels,audioFlags];
    [AudioFileWrite write2FilePath:finalAudioFileName
                   withAudioFormat:&recordAsbd
                         audioData:self.finalPcmData
                      audioPackets:(UInt32)self.finalConverPackets];
}

@end
