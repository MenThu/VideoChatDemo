//
//  AudioManager.h
//  VideoChatDemo
//
//  Created by menthu on 2022/8/23.
//  Copyright © 2022 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioManager : NSObject

+ (instancetype)shareInstance;


/*
 暂时只支持44100采样率 双通道 sign int 16bit
 */
- (void)startRecordWithSampleRate:(unsigned int)sampleRate channels:(int)channels sampleBits:(int)sampleBits;
- (void)stopRecord;
- (void)pause;
- (void)resume;

@end

NS_ASSUME_NONNULL_END
