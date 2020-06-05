//
//  MTGLShader.m
//  VideoChatDemo
//
//  Created by menthu on 2020/5/8.
//  Copyright © 2020 menthu. All rights reserved.
//

#import "MTGLShader.h"
#import <GLKit/GLKit.h>

@interface MTGLShader ()

@property (nonatomic, assign, readwrite) GLuint programHandle;

@end

@implementation MTGLShader

- (GLuint)loadShader:(NSString *)vertexFileName fragmentFileName:(NSString *)fileName{
    //1
    GLuint vertexShaderHandle   = [self compileShader:vertexFileName withType:GL_VERTEX_SHADER];
    GLuint fragmentShaderHandle = [self compileShader:fileName withType:GL_FRAGMENT_SHADER];
    
    //2
    self.programHandle = glCreateProgram();
    glAttachShader(self.programHandle, vertexShaderHandle);
    glAttachShader(self.programHandle, fragmentShaderHandle);
    glDeleteShader(vertexShaderHandle);
    glDeleteShader(fragmentShaderHandle);
    glLinkProgram(self.programHandle);
    
    //3
    GLint linkSuccess;
    glGetProgramiv(self.programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(self.programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"compileShader error=[%@]", messageString);
        return -1;
    }
    
//    //4
//    glUseProgram(_programHandle);    
    return self.programHandle;
}

- (void)detachShader{
    glUseProgram(0);
    glDeleteProgram(_programHandle);
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
    //1
    NSError* error = nil;
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    //2
    GLuint shaderHandle = glCreateShader(shaderType);
    
    //3
    const char* shaderStringUTF8 = [shaderString UTF8String];
    
    int shaderStringLength = (int)[shaderString length];
    
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    //4
    glCompileShader(shaderHandle);
    
    //5
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        return -1;
    }
    
    return shaderHandle;
}

@end
