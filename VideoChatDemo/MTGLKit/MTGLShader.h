//
//  MTGLShader.h
//  VideoChatDemo
//
//  Created by menthu on 2020/5/8.
//  Copyright © 2020 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTGLShader : NSObject

- (GLuint)loadShader:(NSString *)vertexFileName fragmentFileName:(NSString *)fileName;
- (void)detachShader;
@property (nonatomic, assign, readonly) GLuint programHandle;

@end

NS_ASSUME_NONNULL_END
