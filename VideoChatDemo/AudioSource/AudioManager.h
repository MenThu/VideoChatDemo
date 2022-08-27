//
//  AudioManager.h
//  VideoChatDemo
//
//  Created by menthu on 2022/8/23.
//  Copyright © 2022 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, AudioCaptureMode) {
    AudioCaptureModeShortInt,
    AudioCaptureModeFloat,
    AudioCaptureModeCanonical,
};

static NSInteger AUDIO_CAPTURE_MODE = YES;

NS_ASSUME_NONNULL_BEGIN

@interface AudioManager : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, assign) AudioCaptureMode mode;
@property (nonatomic, assign) BOOL didLeftRightChannelInterLeaved;

@property (nonatomic, assign) int converSampleRate;
@property (nonatomic, assign) int converChannel;
@property (nonatomic, assign) int converBitsPerChannel;
@property (nonatomic, assign) int converByterate;
@property (nonatomic, assign) AudioCaptureMode converMode;
@property (nonatomic, assign) NSUInteger converStep;//转码步长，1024个采样点转一次码
@property (nonatomic, assign) UInt32 converAudioBufferMaxLength;
@property (nonatomic, assign) void* converAudioBufferPoint;
@property (nonatomic, assign) AudioFormatFlags converFlags;
@property (nonatomic, assign) UInt32 converPackets;

/*
 暂时只支持44100采样率 双通道 sign int 16bit
 */
- (void)startRecordWithSampleRate:(unsigned int)sampleRate channels:(int)channels bitsPerChannel:(int)bitsPerChannel;
- (void)stopRecord;
- (void)pause;
- (void)resume;

- (void)queryHardwareAudioProperty;

@end

NS_ASSUME_NONNULL_END
