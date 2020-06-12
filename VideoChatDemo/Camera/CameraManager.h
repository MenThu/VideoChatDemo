//
//  CameraManager.h
//  VideoChatDemo
//
//  Created by menthu on 2020/6/9.
//  Copyright © 2020 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoFrame.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CameraProtocol <NSObject>

@required
- (void)didCaptureVideoFrame:(VideoFrame *)frame;

@end

@interface CameraManager : NSObject

- (void)startCapture;
- (void)stopCapture;
- (void)switchCameraPosition:(BOOL)isFront;

@property (nonatomic, weak) id<CameraProtocol> cameraDelegate;
@property (nonatomic, assign, readonly) BOOL isRunning;
@property (nonatomic, assign, readonly) BOOL isCameraFront;

@end

NS_ASSUME_NONNULL_END
