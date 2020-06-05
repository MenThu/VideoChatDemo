//
//  MTGLContext.h
//  VideoChatDemo
//
//  Created by menthu on 2020/5/8.
//  Copyright © 2020 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTGLContext : NSObject

- (void)initOpenGL;
- (void)unInitOpenGL;
- (void)prepareForDraw;
- (void)useThisContext;
@property (nonatomic, strong, readonly) EAGLContext *context;
@property (nonatomic, assign, readonly) GLuint frameBuffer;
@property (nonatomic, assign, readonly) GLuint vertexBuffer;
@property (nonatomic, assign, readonly) GLuint indexBuffer;
@property (nonatomic, assign) GLuint programHandle;

@end

NS_ASSUME_NONNULL_END
