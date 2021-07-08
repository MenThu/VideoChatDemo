//
//  VideoFrame.m
//  VideoChatDemo
//
//  Created by menthu on 2020/6/9.
//  Copyright © 2020 menthu. All rights reserved.
//

#import "VideoFrame.h"

@implementation VideoFrame

- (instancetype)init{
    if (self = [super init]) {
        self.yuvBuffer = NULL;
        self.yuvBufferSize = 0;
        self.needMirror = YES;
        self.didRender2Texture = YES;
    }
    return self;
}

@end
