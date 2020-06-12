//
//  MTVideoShader.m
//  VideoChatDemo
//
//  Created by menthu on 2020/6/11.
//  Copyright © 2020 menthu. All rights reserved.
//

#import "MTVideoShader.h"

@interface MTVideoShader ()

@property (nonatomic, assign, readwrite) GLuint vertexPos;
@property (nonatomic, assign, readwrite) GLuint texturePos;
@property (nonatomic, assign, readwrite) GLuint modelTransform;
@property (nonatomic, assign, readwrite) GLuint *textureUniforms;

@end

@implementation MTVideoShader

- (instancetype)init{
    if (self = [super init]) {
        [self loadShader:@"VideoVertex" fragmentFileName:@"VideoFragment"];
        
        self.textureUniforms = (GLuint *)malloc(4 * sizeof(GLuint));
        NSAssert(self.textureUniforms != NULL, @"");
        
        self.vertexPos          = glGetAttribLocation(self.programHandle, "Position");
        self.texturePos         = glGetAttribLocation(self.programHandle, "TextureCoords");
        self.modelTransform     = glGetUniformLocation(self.programHandle, "modelTransform");
        self.textureUniforms[0] = glGetUniformLocation(self.programHandle, "SamplerY");
        self.textureUniforms[1] = glGetUniformLocation(self.programHandle, "SamplerU");
        self.textureUniforms[2] = glGetUniformLocation(self.programHandle, "SamplerV");
    }
    return self;
}

@end
