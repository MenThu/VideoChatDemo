//
//  MTGLRenderTask.h
//  VideoChatDemo
//
//  Created by menthu on 2020/5/8.
//  Copyright © 2020 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "MTVideoShader.h"
#import "MTGLContext.h"
#import "VideoFrame.h"

NS_ASSUME_NONNULL_BEGIN

@class MTGLRenderModel;

@interface MTGLRenderTask : NSObject

@property (nonatomic, strong) MTGLRenderModel *renderModel;
@property (nonatomic, strong) VideoFrame *frame;
- (void)render;
- (void)updateViewPort;

@end

@interface MTGLRenderModel : NSObject

@property (nonatomic, assign) NSUInteger identifier;
@property (nonatomic, assign) CGSize containerSize;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGFloat contentScale;
@property (nonatomic, weak) MTGLContext *glContext;
@property (nonatomic, weak) MTVideoShader *videoShader;
@property (nonatomic, assign) BOOL scale2Fit;

@end

NS_ASSUME_NONNULL_END
