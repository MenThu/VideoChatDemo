//
//  ViewController.m
//  VideoChatDemo
//
//  Created by menthu on 2019/8/25.
//  Copyright © 2019 menthu. All rights reserved.
//

#import <CoreImage/CoreImage.h>
#import "ViewController.h"
#import "GLRenderView.h"
#import "MTGLCanvasView.h"
#import "YUVManager.h"

#define CANVAS_MODE 1

@interface ViewController ()

@property (nonatomic, weak) GLRenderView *renderView;

@property (nonatomic, weak) MTGLCanvasView *glCanvasView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    return;
#if CANVAS_MODE == 1
    [self addCanvasView];
#else
    [self addRenderView];
#endif
    
}

- (void)addRenderView{
    GLRenderView *renderView = [[GLRenderView alloc] init];
    [self.view addSubview:(_renderView = renderView)];
}

- (void)addCanvasView{
    MTGLCanvasView *glCanvasView = [[MTGLCanvasView alloc] init];
    glCanvasView.backgroundColor = UIColor.orangeColor;
    [glCanvasView addImg:@"test2.jpg" inFrame:CGRectMake(10, 200, self.view.bounds.size.width-20, 300) scaleImg2Fit:NO];
    [glCanvasView addImg:@"test1.jpg" inFrame:CGRectMake(0, 100, self.view.bounds.size.width, 200) scaleImg2Fit:NO];
    [self.view addSubview:(_glCanvasView = glCanvasView)];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
#if CANVAS_MODE == 1
    self.glCanvasView.frame = self.view.bounds;
#else
    self.renderView.frame = self.view.bounds;
#endif
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"%s", __FUNCTION__);
    [self.glCanvasView startDisplay];
}

//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    NSInteger temp1 = rand()%5 + 1;
//    NSInteger temp2 = rand()%5 + 1;
//    CGFloat width = self.view.bounds.size.width / temp1;
//    CGFloat height = self.view.bounds.size.width / temp2;
//    CGFloat x = (self.view.bounds.size.width - width)/2;
//    CGFloat y = (self.view.bounds.size.height - height)/2;
//    [UIView animateWithDuration:0.25 animations:^{
//        self.renderView.frame = CGRectMake(x, y, width, height);
//    }];
//}

@end
