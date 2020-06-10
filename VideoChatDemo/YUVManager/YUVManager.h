//
//  YUVManager.h
//  VideoChatDemo
//
//  Created by menthu on 2020/6/10.
//  Copyright © 2020 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NV12ToI420Model : NSObject

@property (nonatomic, assign) unsigned char *src_y;
@property (nonatomic, assign) int src_stride_y;

@property (nonatomic, assign) unsigned char *src_uv;
@property (nonatomic, assign) int src_stride_uv;

@property (nonatomic, assign) unsigned char *dst_y;
@property (nonatomic, assign) int dst_stride_y;

@property (nonatomic, assign) unsigned char *dst_u;
@property (nonatomic, assign) int dst_stride_u;

@property (nonatomic, assign) unsigned char *dst_v;
@property (nonatomic, assign) int dst_stride_v;

@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;

@end

@interface YUVManager : NSObject

+ (NSInteger)converNV12ToI420:(NV12ToI420Model *)converModel;

@end

NS_ASSUME_NONNULL_END
