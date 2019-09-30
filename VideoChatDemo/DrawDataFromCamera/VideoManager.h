//
//  VideoManager.h
//  VideoChatDemo
//
//  Created by menthu on 2019/8/25.
//  Copyright © 2019 menthu. All rights reserved.
//

@class VideoFrame;

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@protocol VideoDelegate <NSObject>

@required
- (void)didCaptureVideoFrame:(VideoFrame *)frame;

@end



@interface VideoManager : NSObject

- (instancetype)initWithDelegate:(id<VideoDelegate>)delegate isFront:(BOOL)isFront;
- (void)startCapture;
- (void)stopCapture;
- (void)switchCameraPosition:(BOOL)isFront;

- (void)getOneFrame:(void (^) (CVPixelBufferRef imgeData))callBack;

@end
