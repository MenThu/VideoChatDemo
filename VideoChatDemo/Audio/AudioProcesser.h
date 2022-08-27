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

@interface AudioProcesser : NSObject

- (instancetype)initWithOriginSampleRate:(Float64)sampleRate
                          originChannels:(UInt32)channels
                  originAudioFormatFlags:(AudioFormatFlags)audioFormatFlags
                   originAudioStreamDesc:(AudioStreamBasicDescription)originAudioDesc
                        originSampleStep:(UInt32)originSampleStep
                        converSampleRate:(Float64)converSampleRate
                          converChannels:(UInt32)converChannels
                  converAudioFormatFlags:(AudioFormatFlags)converAudioFormatFlags
                          converCallback:(ConverAudioCallBack)converCallback;

- (void)inputOrignAudioData:(void *)audioBuffer audioLength:(NSUInteger)audioLength numPackets:(UInt32)numPackets;

@property (nonatomic, assign, readonly) AudioStreamBasicDescription converAudioDesc;

@end

NS_ASSUME_NONNULL_END
