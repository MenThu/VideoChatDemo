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

@interface ViewController ()

@property (nonatomic, weak) GLRenderView *renderView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GLRenderView *renderView = [[GLRenderView alloc] init];
    [self.view addSubview:(_renderView = renderView)];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.renderView.frame = self.view.bounds;
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
