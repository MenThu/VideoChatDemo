//
//  YUVManager.h
//  VideoChatDemo
//
//  Created by menthu on 2020/6/10.
//  Copyright © 2020 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YUVManager : NSObject

+ (NSInteger)converNV12:(unsigned char *)src toToI420:(unsigned char *)dst width:(int)nWidth height:(int)nHeight;

@end

NS_ASSUME_NONNULL_END
