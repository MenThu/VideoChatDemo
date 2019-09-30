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
#import "GLViewController.h"

@interface ViewController ()

@property (weak, nonatomic) GLRenderView *renderView;
@property (weak, nonatomic) UIImageView *snapShotImgView;
@property (strong, nonatomic) VideoManager *videoManager;
@property (assign, nonatomic) BOOL isCapture;
@property (weak, nonatomic) UIButton *switchButon;
@property (assign, nonatomic) BOOL isFront;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isCapture = NO;
    GLRenderView *renderView = [[GLRenderView alloc] init];
    [self.view addSubview:(_renderView = renderView)];
    self.videoManager = [[VideoManager alloc] initWithDelegate:renderView isFront:(_isFront = YES)];
    
    UIButton *switchButon = [UIButton buttonWithType:UIButtonTypeCustom];
    switchButon.backgroundColor = UIColor.orangeColor;
    [switchButon addTarget:self action:@selector(switchCameraAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:(_switchButon = switchButon)];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.renderView.frame = self.view.bounds;
    CGFloat buttonSize = 50.f;
    self.switchButon.frame = CGRectMake(self.view.bounds.size.width - buttonSize - 20, 20, buttonSize, buttonSize);
}

- (void)switchCameraAction{
    self.isFront = !self.isFront;
    [self.videoManager switchCameraPosition:self.isFront];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self startCapture];
}

- (void)startCapture{
    if (!self.isCapture) {
        [self.videoManager startCapture];
    }else{
        [self.videoManager stopCapture];
    }
    self.isCapture = !self.isCapture;
}

@end
