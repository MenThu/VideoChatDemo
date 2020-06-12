//
//  YUVManager.m
//  VideoChatDemo
//
//  Created by menthu on 2020/6/10.
//  Copyright © 2020 menthu. All rights reserved.
//

#import "YUVManager.h"
#import <libyuv/convert.h>

@implementation YUVManager

+ (NSInteger)converNV12:(unsigned char *)src toToI420:(unsigned char *)dst width:(int)nWidth height:(int)nHeight{
    return libyuv::NV12ToI420(src, nWidth,
                              src + nWidth * nHeight, nWidth,
                              dst, nWidth,
                              dst + nWidth * nHeight, nWidth >> 1,
                              dst + nWidth * nHeight * 5 / 4, nWidth >> 1,
                              nWidth, nHeight);
}

@end
