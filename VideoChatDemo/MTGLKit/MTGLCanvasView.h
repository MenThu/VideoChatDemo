//
//  MTGLCanvasView.h
//  VideoChatDemo
//
//  Created by menthu on 2020/5/8.
//  Copyright © 2020 menthu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTGLRenderTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTGLCanvasView : UIView

@property (nonatomic, strong, readonly) NSMutableArray <MTGLRenderTask *> *taskArray;

- (void)addRenderTask:(CGRect)frame withIdentifier:(NSUInteger)identifier;
- (void)startDisplay;
- (void)stopDisplay;


@end

NS_ASSUME_NONNULL_END
