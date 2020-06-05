//
//  MTGLRenderTask.h
//  VideoChatDemo
//
//  Created by menthu on 2020/5/8.
//  Copyright © 2020 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "MTImgShader.h"
#import "MTGLContext.h"

NS_ASSUME_NONNULL_BEGIN

@class MTGLRenderModel;

@interface MTGLRenderTask : NSObject

@property (nonatomic, strong) MTGLRenderModel *renderModel;

- (void)render;

@end

@interface MTGLRenderModel : NSObject

@property (nonatomic, strong) NSString *imgName;
@property (nonatomic, assign) CGSize containerSize;
@property (nonatomic, assign) BOOL scaleImg2Fit;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGFloat contentScale;
@property (nonatomic, weak) MTGLContext *glContext;
@property (nonatomic, weak) MTImgShader *imgShader;

@end

NS_ASSUME_NONNULL_END
