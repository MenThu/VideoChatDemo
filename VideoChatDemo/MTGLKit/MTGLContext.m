//
//  MTGLContext.m
//  VideoChatDemo
//
//  Created by menthu on 2020/5/8.
//  Copyright © 2020 menthu. All rights reserved.
//

#import "MTGLContext.h"
#import "MTGLHead.h"

@interface MTGLContext ()

@property (nonatomic, assign) BOOL isInit;
@property (nonatomic, strong, readwrite) EAGLContext *context;
@property (nonatomic, assign, readwrite) GLuint frameBuffer;
@property (nonatomic, assign, readwrite) GLuint vertexBuffer;
@property (nonatomic, assign, readwrite) GLuint indexBuffer;

@end

@implementation MTGLContext

- (void)initOpenGL{
    if (!self.isInit) {
        self.isInit = YES;
        [self prepareForGL];
    }
}

- (void)dealloc{
    [self unInitOpenGL];
}

- (void)unInint{
    glDeleteBuffers(1, &self->_frameBuffer);
    glDeleteBuffers(1, &self->_vertexBuffer);
    glDeleteBuffers(1, &self->_indexBuffer);
}

- (void)unInitOpenGL{
    glUseProgram(0);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    if (self.vertexBuffer > 0) {
        glDeleteBuffers(1, &self->_vertexBuffer);
        self.vertexBuffer = 0;
    }

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    if (self.indexBuffer > 0) {
        glDeleteBuffers(1, &self->_indexBuffer);
        self.indexBuffer = 0;
    }

    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
    self.isInit = NO;
}

- (void)prepareForDraw{
    [self useThisContext];
    glBindFramebuffer(GL_FRAMEBUFFER, self.frameBuffer);
    MTGetGLError();
    glUseProgram(self.programHandle);
    MTGetGLError();
}

- (void)prepareForGL{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [self useThisContext];
    glGenFramebuffers(1, &self->_frameBuffer);
    MTGetGLError();
    glGenBuffers(1, &self->_vertexBuffer);
    MTGetGLError();
    glGenBuffers(1, &self->_indexBuffer);
    MTGetGLError();
}

- (void)useThisContext{
    if (EAGLContext.currentContext != self.context) {
        if (![EAGLContext setCurrentContext:self.context]) {
            MTLog(@"设置EAGLContext失败");
            MTGetGLError();
        }
    }
}

@end
