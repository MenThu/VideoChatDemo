//
//  MTGLTool.h
//  VideoChatDemo
//
//  Created by menthu on 2020/6/2.
//  Copyright © 2020 menthu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
void executeTaskInQueue(BOOL isSync, dispatch_block_t _Nonnull task);
#ifdef __cplusplus
}
#endif

@interface MTGLTool : NSObject

@end

NS_ASSUME_NONNULL_END
