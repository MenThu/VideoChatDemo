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
#import "CameraManager.h"

#define CANVAS_MODE 1

@interface ViewController () <CameraProtocol>

@property (nonatomic, weak) GLRenderView *renderView;
@property (nonatomic, weak) MTGLCanvasView *glCanvasView;
@property (nonatomic, strong) CameraManager *cameraManager;
@property (weak, nonatomic) IBOutlet UIButton *addRenderTaskButton;

@property (nonatomic, strong) NSMutableArray <NSValue *> *renderTaskFrameArray;
@property (nonatomic, assign) NSInteger currentTaskCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initData];
    [self initCanvasView];
    [self initCameraManager];
}

- (void)initData{
    self.currentTaskCount = 0;
    self.renderTaskFrameArray = [NSMutableArray array];
    
    [self.renderTaskFrameArray addObject:[NSValue valueWithCGRect:self.view.bounds]];
    [self.renderTaskFrameArray addObject:[NSValue valueWithCGRect:CGRectMake(10, 220, 100, 100)]];
    [self.renderTaskFrameArray addObject:[NSValue valueWithCGRect:CGRectMake(150, 220, 100, 100)]];
    [self.renderTaskFrameArray addObject:[NSValue valueWithCGRect:CGRectMake(10, 340, 100, 100)]];
    [self.renderTaskFrameArray addObject:[NSValue valueWithCGRect:CGRectMake(150, 340, 100, 100)]];
    
}

- (void)initCameraManager{
    self.cameraManager = [CameraManager new];
    self.cameraManager.cameraDelegate = self;
}

- (void)initCanvasView{
    MTGLCanvasView *glCanvasView = [[MTGLCanvasView alloc] init];
    glCanvasView.userInteractionEnabled = NO;
    glCanvasView.backgroundColor = UIColor.orangeColor;
    [self.view insertSubview:(_glCanvasView = glCanvasView) atIndex:0];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.glCanvasView.frame = self.view.bounds;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (self.cameraManager.isRunning) {
        [self.cameraManager stopCapture];
        [self.glCanvasView stopDisplay];
    }else{
        [self.cameraManager startCapture];
        [self.glCanvasView startDisplay];
    }
}

- (void)didCaptureVideoFrame:(VideoFrame *)frame{
    GLuint *texture = NULL;
    for (NSInteger i = 0; i < self.glCanvasView.taskArray.count; i ++) {
        MTGLRenderTask *renderTask = self.glCanvasView.taskArray[i];
        if (texture != NULL) {
            frame.planarTexture = texture;
        }
        renderTask.frame = frame;
        if (texture == NULL && frame.planarTexture != NULL) {
            texture = frame.planarTexture;
        }
    }
    free(frame.yuvBuffer);
    frame.yuvBuffer = NULL;
}

- (IBAction)addRenderTask:(UIButton *)sender{
    if (self.currentTaskCount < self.renderTaskFrameArray.count) {
        [self.glCanvasView addRenderTask:self.renderTaskFrameArray[self.currentTaskCount].CGRectValue withIdentifier:self.currentTaskCount];
        ++self.currentTaskCount;
    }
    if (self.cameraManager.isRunning == NO) {
        [self.cameraManager startCapture];
        [self.glCanvasView startDisplay];
    }
}

- (IBAction)switchCamera:(id)sender {
    [self.cameraManager switchCameraPosition:!self.cameraManager.isCameraFront];
}


@end
