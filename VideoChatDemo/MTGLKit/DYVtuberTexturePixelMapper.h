//
//  DYVtuberTexturePixelMapper.h
//  VideoChatDemo
//
//  Created by menthu on 2021/7/7.
//  Copyright © 2021 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

@interface DYVtuberTexturePixelMapper : NSObject

@property (nonatomic, readonly) CGSize texturePixelSize;
@property (nonatomic, readonly) GLuint offscreenTexture;

/// 渲染后的像素数据，应该送去编码推流
@property (nonatomic, readonly) CVPixelBufferRef pixelBuffer;

/// 创建一个CVPixelBuffer与OpenGL ES纹理内存映射的mapper
/// @param texturePixelSize OpenGL ES纹理的大小，单位为像素
- (instancetype)initWithPixelSize:(CGSize)texturePixelSize;

@end

NS_ASSUME_NONNULL_END
