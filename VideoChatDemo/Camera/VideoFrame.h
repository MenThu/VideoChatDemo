//
//  VideoFrame.h
//  VideoChatDemo
//
//  Created by menthu on 2020/6/9.
//  Copyright © 2020 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoFrame : NSObject

@property (nonatomic, assign) unsigned char *yuvBuffer;
@property (nonatomic, assign) size_t yuvBufferSize;
@property (nonatomic, assign) size_t width;
@property (nonatomic, assign) size_t height;

@end

NS_ASSUME_NONNULL_END
