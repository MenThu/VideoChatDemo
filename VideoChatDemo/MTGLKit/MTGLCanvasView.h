//
//  MTGLCanvasView.h
//  VideoChatDemo
//
//  Created by menthu on 2020/5/8.
//  Copyright © 2020 menthu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTGLCanvasView : UIView

- (void)addImg:(NSString *)imgName inFrame:(CGRect)frame scaleImg2Fit:(BOOL)scaleImg2Fit;
- (void)startDisplay;
- (void)stopDisplay;

@end

NS_ASSUME_NONNULL_END
