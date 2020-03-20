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

@end
