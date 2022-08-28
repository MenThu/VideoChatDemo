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

@property (nonatomic, strong) DYAudioProperty *sourceProperty;
@property (nonatomic, strong) DYAudioProperty *targetProperty;

@property (nonatomic, assign) UInt32 sourceConverStep;
@property (nonatomic, assign) UInt32 targetConverPackets;
@property (nonatomic, assign) UInt32 sourceStepLength;

@property (nonatomic, strong) NSMutableData *pendingAudioData;
@property (nonatomic, assign) UInt32 pendingPackets;
@property (nonatomic, assign) void *converAudioBuffer;
@property (nonatomic, assign) UInt32 converAudioLength;
@property (nonatomic, assign) BOOL shoudAudioConverFuncProvideMoreAudioData;
@property (nonatomic, weak) NSThread *converAudioDataThread;

@property (nonatomic, copy) ConverAudioCallBack converAudioCallback;
@property (nonatomic, assign, readwrite) AudioStreamBasicDescription converAudioDesc;
@property (nonatomic, assign) AudioConverterRef audioConverterRef;


@end

@implementation AudioProcesser

#pragma mark - LifeCycle
- (instancetype)initWithSourceAudioProperty:(DYAudioProperty *)sourceAduioProperty
                        targetAudioProperty:(DYAudioProperty *)targetAudioProperty
                           converSampleStep:(UInt32)converSampleStep
                             converCallback:(ConverAudioCallBack)converCallback{
    if (self = [super init]) {
        self.sourceProperty = sourceAduioProperty;
        self.targetProperty = targetAudioProperty;
        
        self.sourceConverStep = converSampleStep;
        self.sourceStepLength = self.sourceConverStep * sourceAduioProperty.bytePerSample;
        float targetConverPacket = ((float)self.sourceConverStep/sourceAduioProperty.audioDesc.mSampleRate) *
        targetAudioProperty.audioDesc.mSampleRate;
        self.targetConverPackets =
        (targetAudioProperty.roundup ? ceilf(targetConverPacket) : floorf(targetConverPacket));
        
        self.pendingPackets = 0;
        self.pendingAudioData = [NSMutableData data];
        
        
        self.converAudioLength = self.targetConverPackets * targetAudioProperty.bytePerSample;
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
- (void)processAudioBuffer:(void *)audioBuffer audioLength:(NSUInteger)audioLength audioPackets:(UInt32)audioPackets{
    @autoreleasepool {
        self.pendingPackets += audioPackets;
        [self.pendingAudioData appendBytes:audioBuffer length:audioLength];
        
        void *tempBuffer = (void *)self.pendingAudioData.bytes;
        while (self.pendingPackets / self.sourceConverStep >= 1) {
            NSData *audioData = [NSData dataWithBytes:tempBuffer length:self.sourceStepLength];
            [self doAudioConver:audioData];
            self.pendingPackets -= self.sourceConverStep;
            tempBuffer += self.sourceStepLength;
        }
        UInt32 leftLength = self.pendingPackets * self.sourceProperty.bytePerSample;
        self.pendingAudioData = [NSMutableData dataWithBytes:tempBuffer length:leftLength];
    }
}

- (void)endProcessed{
    self.pendingAudioData = nil;
}

#pragma mark - AudioConver相关
- (void)setupAudioConver{
    [self releaseAudioConverIfNeed];
    AudioStreamBasicDescription source = self.sourceProperty.audioDesc;
    AudioStreamBasicDescription target = self.targetProperty.audioDesc;
    OSStatus result = AudioConverterNew(&source, &target, &_audioConverterRef);
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

- (void)doAudioConver:(NSData *)audioData{
    bzero(self.converAudioBuffer, self.converAudioLength);
    AudioBufferList outBuffer;
    outBuffer.mNumberBuffers = 1;
    outBuffer.mBuffers[0].mDataByteSize = self.converAudioLength;
    outBuffer.mBuffers[0].mData = self.converAudioBuffer;
    outBuffer.mBuffers[0].mNumberChannels = self.targetProperty.audioDesc.mChannelsPerFrame;
    
    self.shoudAudioConverFuncProvideMoreAudioData = YES;
    self.converAudioDataThread = NSThread.currentThread;
    
    UInt32 converPackets = self.targetConverPackets;
    
    NSArray *args = @[self, audioData];
    
    OSStatus result = AudioConverterFillComplexBuffer(_audioConverterRef,
                                                      AudioConverterFiller,
                                                      (__bridge void *)(args),
                                                      &converPackets,
                                                      &outBuffer,
                                                      NULL);
    if (result == noErr || result == NO_MORE_AUDIO_DATA) {
        LoggerInfo(kLoggerLevel, @"samplerate=[%u][%u] request=[%u] actual=[%u] buffersize=[%u]",
                   (UInt32)self.sourceProperty.audioDesc.mSampleRate,
                   (UInt32)self.targetProperty.audioDesc.mSampleRate,
                   self.targetConverPackets,
                   converPackets,
                   outBuffer.mBuffers[0].mDataByteSize);
        self.converAudioCallback(outBuffer.mBuffers[0], converPackets);
    }else{
        [AudioExt checkResult:result operation:"onInputPCMData"];
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
        LoggerInfo(kLoggerLevel, @"originAudioData should not be null, please check");
        return NO_MORE_AUDIO_DATA;
    }
    *ioNumberDataPackets = audioConver.sourceConverStep;
    
    ioData->mBuffers[0].mData = (void *)originAudioData.bytes;
    ioData->mBuffers[0].mDataByteSize = (UInt32)originAudioData.length;
    ioData->mBuffers[0].mNumberChannels = audioConver.targetProperty.audioDesc.mChannelsPerFrame;
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

@implementation DYAudioProperty

@end
