//
//  VideoFrame.h
//  VideoChatDemo
//
//  Created by menthu on 2020/6/9.
//  Copyright © 2020 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, VideoFormat) {
    VideoFormatI420,
    VideoFormatNV21,
    VideoFormatNV12,
};

typedef NS_ENUM(NSInteger, VideoRotation) {
    VideoRotation_0 = 0,   // 不旋转。
    VideoRotation_90 = 1,  // 顺时针旋转90度。
    VideoRotation_180 = 2, // 顺时针旋转180度。
    VideoRotation_270 = 3, // 顺时针旋转270度。
};

NS_ASSUME_NONNULL_BEGIN

@interface VideoFrame : NSObject

@property (nonatomic, assign, nullable) unsigned char *yuvBuffer;
@property (nonatomic, assign) size_t yuvBufferSize;
@property (nonatomic, assign) size_t width;
@property (nonatomic, assign) size_t height;
@property (nonatomic, assign) VideoFormat format;
@property (nonatomic, assign) VideoRotation rotation;
@property (nonatomic, assign) BOOL needMirror;


@property (nonatomic, assign) uint32_t *planarTexture;

@end

NS_ASSUME_NONNULL_END
