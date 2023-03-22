//
//  AudioConver.h
//  VideoChatDemo
//
//  Created by menthu on 2022/8/27.
//  Copyright © 2022 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ConverAudioCallBack)(AudioBuffer converAudioBuffer, UInt32 converPackets);

@interface DYAudioProperty : NSObject

/// 音频属性描述信息
@property (nonatomic, assign) AudioStreamBasicDescription audioDesc;

/// 采样率转换时一般存在小数，比如1024个48K的采样点转成44.1K后，采样点变成=1024*44.1/48=940.8，通过rounup指定向上或者向下取整
@property (nonatomic, assign) BOOL roundup;

/// 采样点大小：仅考虑左右交织的情况，所以大小=channel*bitsPerChannel/8;
@property (nonatomic, assign) UInt32 bytePerSample;

@end

@interface AudioProcesser : NSObject

- (instancetype)initWithSourceAudioProperty:(DYAudioProperty *)sourceAduioProperty
                        targetAudioProperty:(DYAudioProperty *)targetAudioProperty
                           converSampleStep:(UInt32)converSampleStep
                             converCallback:(ConverAudioCallBack)converCallback;
- (void)processAudioBuffer:(void *)audioBuffer audioLength:(NSUInteger)audioLength audioPackets:(UInt32)audioPackets;
- (void)endProcessed;

@end

NS_ASSUME_NONNULL_END
