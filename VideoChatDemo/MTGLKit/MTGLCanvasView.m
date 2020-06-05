//
//  MTGLCanvasView.m
//  VideoChatDemo
//
//  Created by menthu on 2020/5/8.
//  Copyright © 2020 menthu. All rights reserved.
//

#import "MTGLCanvasView.h"
#import "MTGLContext.h"
#import "MTImgShader.h"
#import "MTGLRenderTask.h"
#import "MTGLTool.h"
#import "MTGLHead.h"

@interface MTGLCanvasView ()

@property (nonatomic, strong) MTGLContext *glContext;
@property (nonatomic, strong) MTImgShader *glShader;
@property (nonatomic, assign) BOOL isOpenGLInit;
@property (nonatomic, assign) GLuint renderBuffer;
@property (nonatomic, assign) CGSize pixelSize;
@property (nonatomic, strong) NSMutableArray <MTGLRenderTask *> *taskArray;
@property (nonatomic, weak) MTGLRenderTask *touchTask;
@property (nonatomic, assign) CGPoint touchPoint;

@end

@implementation MTGLCanvasView

+ (Class)layerClass{
    return [CAEAGLLayer class];
}

- (instancetype)init{
    if (self = [super init]) {
        [self initData];
        [self initOpenGL];
    }
    return self;
}

- (void)initData{
    self.isOpenGLInit = NO;
    self.taskArray = @[].mutableCopy;
    self.contentScaleFactor = UIScreen.mainScreen.scale;
}

- (void)initOpenGL{
    if (!self.isOpenGLInit) {
        self.isOpenGLInit = YES;

        MTGLContext *glContext = [[MTGLContext alloc] init];
        [glContext initOpenGL];
        [glContext useThisContext];
        self.glContext = glContext;
        glGenRenderbuffers(1, &self->_renderBuffer);
        
        MTImgShader *glShader = [[MTImgShader alloc] init];
        self.glShader = glShader;
        self.glContext.programHandle = self.glShader.programHandle;
        
        self.taskArray = [NSMutableArray array];
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    GLint pixelWidth = 0;
    GLint pixelHeight = 0;
    glBindRenderbuffer(GL_RENDERBUFFER, self.renderBuffer);
    [self.glContext useThisContext];
    [self.glContext.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &pixelWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &pixelHeight);
    self.pixelSize = CGSizeMake(pixelWidth, pixelHeight);
    
    for (MTGLRenderTask *task in self.taskArray) {
        MTGLRenderModel *renderModel = task.renderModel;
        renderModel.containerSize = self.pixelSize;
        task.renderModel = renderModel;
    }
}

- (void)startDisplay{
    [self.glContext prepareForDraw];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,
                              self.renderBuffer);
    glClearColor(0.f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    for (MTGLRenderTask *task in self.taskArray) {
        [task render];
    }
    [self.glContext.context presentRenderbuffer:GL_RENDERBUFFER];
    MTGetGLError();
}

- (void)stopDisplay{
    glClearColor(0.f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)addImg:(NSString *)imgName inFrame:(CGRect)frame scaleImg2Fit:(BOOL)scaleImg2Fit{
    MTGLRenderModel *renderModel = [[MTGLRenderModel alloc] init];
    renderModel.imgName = imgName;
    renderModel.containerSize = self.pixelSize;
    renderModel.scaleImg2Fit = scaleImg2Fit;
    renderModel.frame = frame;
    renderModel.imgShader = self.glShader;
    renderModel.glContext = self.glContext;
    renderModel.contentScale = self.contentScaleFactor;

    MTGLRenderTask *task = [[MTGLRenderTask alloc] init];
    task.renderModel = renderModel;
    [self.taskArray addObject:task];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.touchPoint = [touches.anyObject locationInView:self];
    for (NSInteger index = self.taskArray.count-1; index >= 0; index --) {
        if (CGRectContainsPoint(self.taskArray[index].renderModel.frame, self.touchPoint)) {
            self.touchTask = self.taskArray[index];
            break;
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (self.touchTask == nil) {
        return;
    }
    CGPoint movePoint = [touches.anyObject locationInView:self];
    CGFloat xDistance = movePoint.x - self.touchPoint.x;
    CGFloat yDistance = movePoint.y - self.touchPoint.y;
    self.touchPoint = movePoint;
    CGRect frame = self.touchTask.renderModel.frame;
    self.touchTask.renderModel.frame = CGRectMake(frame.origin.x + xDistance, frame.origin.y + yDistance, frame.size.width, frame.size.height);
    
    
    [self startDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.touchTask = nil;
}

@end
