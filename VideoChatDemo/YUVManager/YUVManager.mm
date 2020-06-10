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

+ (NSInteger)converNV12ToI420:(NV12ToI420Model *)converModel{
   return libyuv::NV12ToI420(converModel.src_y, 0, converModel.src_uv, 0, converModel.dst_y, 0, converModel.dst_u, 0, converModel.dst_v, 0, 0, 0);
}

@end


@implementation NV12ToI420Model


@end
