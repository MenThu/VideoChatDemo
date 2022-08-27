//
//  AudioFileWrite.h
//  VideoChatDemo
//
//  Created by menthu on 2022/8/26.
//  Copyright © 2022 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioFileWrite : NSObject



/// 默认创建一个WAVE的音频文件，如果文件之前存在则直接覆盖；返回NO代表写入失败
/// @param filePath 文件全路径
/// @param format 音频流格式
/// @param pcmAudioData 待写入的音频数据
/// @param audioPackets 音频包数
+ (BOOL)write2FilePath:(NSString *)filePath
       withAudioFormat:(const AudioStreamBasicDescription *)format
             audioData:(NSData *)pcmAudioData
          audioPackets:(UInt32)audioPackets;

@end

NS_ASSUME_NONNULL_END
