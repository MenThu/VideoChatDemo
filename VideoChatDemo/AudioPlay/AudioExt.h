//
//  AudioExt.h
//  VideoChatDemo
//
//  Created by menthu on 2022/8/27.
//  Copyright © 2022 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define kLoggerLevel 1
#define LoggerInfo(level, format, ...) NSLog((@"[%s][%d] " format), __func__, __LINE__, ##__VA_ARGS__)

NS_ASSUME_NONNULL_BEGIN

@interface AudioExt : NSObject

/// 根据指定参数创建AudioStreamBasicDesc 对于多声道的情况，内部仅实现了左右升到交织的配置
/// @param sampleRate 采样率
/// @param channelPerSample 声道数
/// @param bitsPerChannel 声道位深
/// @param AudioID kAudioFormatLinearPCM/kAudioFormatMPEG4AAC
/// @param formatFlags 采样点特性
+ (AudioStreamBasicDescription)createAudioBasicDescWithSampleRate:(Float64)sampleRate
                                                 channelPerSample:(UInt32)channelPerSample
                                                   bitsPerChannel:(UInt32)bitsPerChannel
                                                          AudioID:(AudioFormatID)AudioID
                                                      formatFlags:(AudioFormatFlags)formatFlags;



/// 检查错误码 返回错误对应的FourCC解释
/// @param result 错误码
/// @param operation 调用方对错误打的tag
+ (void)checkResult:(OSStatus)result operation:(const char *)operation;

@end

NS_ASSUME_NONNULL_END
