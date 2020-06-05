//
//  MTImgShader.h
//  VideoChatDemo
//
//  Created by menthu on 2020/5/8.
//  Copyright © 2020 menthu. All rights reserved.
//

#import "MTGLShader.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTImgShader : MTGLShader

@property (nonatomic, assign, readonly) GLuint vertexPos;
@property (nonatomic, assign, readonly) GLuint texturePos;
@property (nonatomic, assign, readonly) GLuint textureUniform;

@end

NS_ASSUME_NONNULL_END
