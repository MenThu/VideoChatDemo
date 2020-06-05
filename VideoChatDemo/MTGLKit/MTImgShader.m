//
//  MTImgShader.m
//  VideoChatDemo
//
//  Created by menthu on 2020/5/8.
//  Copyright © 2020 menthu. All rights reserved.
//

#import "MTImgShader.h"

@interface MTImgShader ()

@property (nonatomic, assign, readwrite) GLuint vertexPos;
@property (nonatomic, assign, readwrite) GLuint texturePos;
@property (nonatomic, assign, readwrite) GLuint textureUniform;

@end

@implementation MTImgShader

- (instancetype)init{
    if (self = [super init]) {
        [self loadShader:@"vertex" fragmentFileName:@"fragment"];
        
        self.vertexPos      = glGetAttribLocation(self.programHandle, "Position");
        self.texturePos     = glGetAttribLocation(self.programHandle, "TextureCoords");
        self.textureUniform = glGetUniformLocation(self.programHandle, "Texture");
    }
    return self;
}

@end
