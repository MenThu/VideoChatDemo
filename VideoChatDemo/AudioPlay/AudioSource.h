//
//  AudioSource.h
//  VideoChatDemo
//
//  Created by menthu on 2022/8/27.
//  Copyright © 2022 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolBox/AudioToolBox.h>
#import "AudioExt.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^AudioDataCallBack)(AudioBuffer audioBuffer, UInt32 audioPackets);

@interface AudioSource : NSObject

+ (void)enableAudioSession;
- (instancetype)initWithSampleRate:(Float64)sampleRate
                          channels:(UInt32)channels
                  audioFormatFlags:(AudioFormatFlags)audioFormatFlags
                          callback:(AudioDataCallBack)callback;
- (void)startRecord:(void (^) (BOOL succ))callback;
- (void)pause;
- (void)resume;
- (void)stopRecord;

@property (nonatomic, assign, readonly) AudioStreamBasicDescription recordAudioDesc;
@property (nonatomic, assign) BOOL isAudioUnitRemoteIO;

@end

NS_ASSUME_NONNULL_END
