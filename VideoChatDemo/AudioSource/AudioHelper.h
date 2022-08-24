//
//  AudioHelper.h
//  VideoChatDemo
//
//  Created by menthu on 2022/8/23.
//  Copyright © 2022 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioHelper : NSObject

+ (void)savePCMData:(NSData *)pcmData
         sampleRate:(int)sampleRate
         channelNum:(int)channelNum
         toFilename:(NSString *)filename;

@end

NS_ASSUME_NONNULL_END
