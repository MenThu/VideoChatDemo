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

@interface AudioController ()

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


@property (nonatomic, assign) UInt32 originSampleStep;
@property (nonatomic, assign) UInt32 converSampleRate;
@property (nonatomic, assign) UInt32 converChannels;
@property (nonatomic, assign) BOOL converInt;
@property (nonatomic, strong) AudioProcesser *audioConver;
@property (nonatomic, strong) NSMutableData *converPcmData;
@property (nonatomic, assign) UInt64 converPackets;

@end

@implementation AudioController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    LoggerInfo(kLoggerLevel, @"init mic aduio source");
    
    self.recordAudioPcm = [NSMutableData data];
    self.recordInt = NO;
    __weak typeof(self) weakSelf = self;
    self.recordSampleRate = 48000;
    self.recordChannels = 2;
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

- (void)setupAudioConver{
    __weak typeof(self) weakSelf = self;
    self.converCount = 0;
    self.originSampleStep = 1024;
    self.converInt = YES;
    Float64 converSampleRate = 44100;
    UInt32 converChannels = 1;
    self.converSampleRate = converSampleRate;
    self.converChannels = converChannels;
    AudioFormatFlags converAudioFlags = kAudioFormatFlagIsPacked;
    if (self.converInt) {
        converAudioFlags |= kAudioFormatFlagIsSignedInteger;
    }else{
        converAudioFlags |= kAudioFormatFlagIsFloat;
    }
    self.converPcmData = [NSMutableData data];
    self.audioConver = [[AudioProcesser alloc] initWithOriginSampleRate:self.recordSampleRate
                                                         originChannels:self.recordChannels
                                                 originAudioFormatFlags:self.micAudioSource.recordAudioDesc.mFormatFlags
                                                  originAudioStreamDesc:self.micAudioSource.recordAudioDesc
                                                       originSampleStep:self.originSampleStep
                                                       converSampleRate:converSampleRate
                                                         converChannels:converChannels
                                                 converAudioFormatFlags:converAudioFlags
                                                         converCallback:^(AudioBuffer converAudioBuffer,
                                                                          UInt32 converPackets) {
        [weakSelf converAudioData:converAudioBuffer converPackets:converPackets];
    }];
}

- (void)converAudioData:(AudioBuffer)audioBuffer converPackets:(UInt32)converPackets{
    [self.converPcmData appendBytes:audioBuffer.mData
                             length:audioBuffer.mDataByteSize];
    self.converPackets += converPackets;
}

- (void)recordAudioData:(AudioBuffer)buffer audioPackets:(UInt32)audioPackets{
    if (buffer.mData == NULL
        || buffer.mDataByteSize <= 0) {
        LoggerInfo(kLoggerLevel, @"callback audio data error");
        return;
    }
    [self.recordAudioPcm appendBytes:buffer.mData length:buffer.mDataByteSize];
    self.totalSample += audioPackets;
    self.currentSample += audioPackets;
    if (self.currentSample > self.originSampleStep) {
        self.currentSample -= self.originSampleStep;
        void *buffer = (void *)self.recordAudioPcm.bytes;
        buffer = buffer + (self.converCount * self.originSampleStep * self.recordBytePerSample);
        UInt32 length = self.originSampleStep * self.recordBytePerSample;
        [self.audioConver inputOrignAudioData:buffer audioLength:length numPackets:self.originSampleStep];
        ++self.converCount;
    }
}

- (IBAction)onStartClick:(UIButton *)sender {
    [self.micAudioSource startRecord:^(BOOL succ) {
        if (!succ) {
            LoggerInfo(kLoggerLevel, @"startRecord error");
        }else{
            [self setupAudioConver];
        }
    }];
    
    /*
     //     NSLog(@"%s", __FUNCTION__);
     //     int channel = 1;
     //     int sampleRate = 44100;
     //     int sampleBits = -1;
     //     AudioManager.shareInstance.mode = AudioCaptureModeShortInt;
     //     AudioManager.shareInstance.didLeftRightChannelInterLeaved = YES;
     //     switch (AudioManager.shareInstance.mode) {
     //         case AudioCaptureModeShortInt:
     //         {
     //             sampleBits = sizeof(short) * 8;
     //         }
     //             break;
     //         case AudioCaptureModeFloat:
     //         {
     //             sampleBits = sizeof(float) * 8;
     //         }
     //             break;
     //         case AudioCaptureModeCanonical:
     //         {
     //             sampleBits = sizeof(AudioUnitSampleType) * 8;
     //         }
     //             break;
     //
     //         default:
     //             break;
     //     }
     //
     //
     //     int converSampleRate = 16000;
     //     int converChannel = 2;
     //     BOOL conver2Int = NO;
     //     int converBitsPerChannel = sizeof(short) * 8;
     //     if (conver2Int) {
     //         converBitsPerChannel = sizeof(short) * 8;
     //         AudioManager.shareInstance.converMode = AudioCaptureModeShortInt;
     //         AudioManager.shareInstance.converFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
     //     }else{
     //         converBitsPerChannel = sizeof(float) * 8;
     //         AudioManager.shareInstance.converMode = AudioCaptureModeFloat;
     //         AudioManager.shareInstance.converFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
     //     }
     //
     //     int converByteRate = converSampleRate * converChannel * (converBitsPerChannel/8);
     //     int converStep = 1024;
     //
     //
     //     UInt32 converSampleStep = (int)floorf((converStep*1.f/sampleRate) * converSampleRate);
     //
     //     UInt32 converAudioBufferMaxLength = converSampleStep * converChannel * (converBitsPerChannel/8);
     //     NSLog(@"[%s] converSampleStep=[%u] converAudioBufferMaxLength=[%u]",
     //           __FUNCTION__, converSampleStep, converAudioBufferMaxLength);
     //     //(UInt32)(converStep * converChannel * (converBitsPerChannel/8));
     //     void *converAudioBufferPoint = malloc(converAudioBufferMaxLength);
     //     bzero(converAudioBufferPoint, converAudioBufferMaxLength);
     //
     //     AudioManager.shareInstance.converSampleRate = converSampleRate;
     //     AudioManager.shareInstance.converChannel = converChannel;
     //     AudioManager.shareInstance.converBitsPerChannel = converBitsPerChannel;
     //     AudioManager.shareInstance.converByterate = converByteRate;
     //     AudioManager.shareInstance.converStep = converStep;
     //     AudioManager.shareInstance.converAudioBufferMaxLength = converAudioBufferMaxLength;
     //
     //     if (AudioManager.shareInstance.converAudioBufferPoint != NULL) {
     //         free(AudioManager.shareInstance.converAudioBufferPoint);
     //     }
     //     AudioManager.shareInstance.converAudioBufferPoint = converAudioBufferPoint;
     //
     //
     //
     //     [AudioManager.shareInstance startRecordWithSampleRate:sampleRate
     //                                                  channels:channel
     //                                            bitsPerChannel:sampleBits];
     */
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
    AudioStreamBasicDescription converAudioDesc = self.audioConver.converAudioDesc;
    [AudioFileWrite write2FilePath:converFileName
                   withAudioFormat:&converAudioDesc
                         audioData:self.converPcmData
                      audioPackets:(UInt32)self.converPackets];
    
//    [AudioManager.shareInstance stopRecord];
}



@end
