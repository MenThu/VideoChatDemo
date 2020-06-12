//
//  MTVideoShader.h
//  VideoChatDemo
//
//  Created by menthu on 2020/6/11.
//  Copyright © 2020 menthu. All rights reserved.
//

#import "MTGLShader.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTVideoShader : MTGLShader

@property (nonatomic, assign, readonly) GLuint vertexPos;
@property (nonatomic, assign, readonly) GLuint texturePos;
@property (nonatomic, assign, readonly) GLuint modelTransform;
@property (nonatomic, assign, readonly) GLuint *textureUniforms;

@end

NS_ASSUME_NONNULL_END
