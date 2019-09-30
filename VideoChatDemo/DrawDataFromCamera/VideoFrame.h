//
//  VideoFrame.h
//  VideoChatDemo
//
//  Created by menthu on 2019/8/28.
//  Copyright © 2019 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef enum
{
    YUVTYpe_I420,
    YUVTYpe_NV12,
} YUVType;

@interface VideoFrame : NSObject{
@public
    unsigned char *_imgData;
}

@property (assign, nonatomic) YUVType imgType;
@property (assign, nonatomic) int imgWidth;
@property (assign, nonatomic) int imgHeight;
@property (assign, nonatomic) CGFloat imgAngle;
@property (assign, nonatomic) BOOL needMirror;

@end
