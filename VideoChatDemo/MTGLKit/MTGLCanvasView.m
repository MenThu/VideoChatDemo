//
//  MTGLCanvasView.m
//  VideoChatDemo
//
//  Created by menthu on 2020/5/8.
//  Copyright © 2020 menthu. All rights reserved.
//

#import "MTGLCanvasView.h"
#import "MTGLContext.h"
#import "MTVideoShader.h"
#import "MTGLTool.h"
#import "MTGLHead.h"
#import "DYVtuberTexturePixelMapper.h"

static NSInteger const RENDER_COUNT_PER_SECOND = 60;

@interface MTGLCanvasView ()

@property (nonatomic, strong) MTGLContext *glContext;
@property (nonatomic, strong) MTVideoShader *glShader;
@property (nonatomic, assign) BOOL isOpenGLInit;
@property (nonatomic, assign) GLuint renderBuffer;
@property (nonatomic, assign) CGSize pixelSize;
@property (nonatomic, strong, readwrite) NSMutableArray <MTGLRenderTask *> *taskArray;
@property (nonatomic, weak) MTGLRenderTask *touchTask;
@property (nonatomic, assign) CGPoint touchPoint;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) DYVtuberTexturePixelMapper *glTexturePixelMapper;


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
    // Get the layer
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking : @NO,
                                     kEAGLDrawablePropertyColorFormat     : kEAGLColorFormatRGBA8 };
    eaglLayer.opaque = YES;
    self.contentScaleFactor = [UIScreen mainScreen].nativeScale;
}

- (void)initOpenGL{
    if (!self.isOpenGLInit) {
        self.isOpenGLInit = YES;

        MTGLContext *glContext = [[MTGLContext alloc] init];
        [glContext initOpenGL];
        [glContext useThisContext];
        self.glContext = glContext;
        glGenRenderbuffers(1, &self->_renderBuffer);
        
        MTVideoShader *glShader = [[MTVideoShader alloc] init];
        self.glShader = glShader;
        self.glContext.programHandle = self.glShader.programHandle;
        
        self.taskArray = [NSMutableArray array];
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
        
    CGSize newSize = self.bounds.size;
    CGFloat scaleFactor = self.window.screen.nativeScale;
    newSize.width *= scaleFactor;
    newSize.height *= scaleFactor;
    if (CGSizeEqualToSize(newSize, CGSizeZero) ||
        CGSizeEqualToSize(newSize, self.pixelSize)) {
        return;
    }
    
    GLint pixelWidth = 0;
    GLint pixelHeight = 0;
    [self.glContext useThisContext];
    glBindRenderbuffer(GL_RENDERBUFFER, self.renderBuffer);
    [self.glContext.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &pixelWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &pixelHeight);
    self.pixelSize = newSize;
    DYVtuberTexturePixelMapper *texturePixelMapper = self.glTexturePixelMapper;
    if (texturePixelMapper == nil ||
        !CGSizeEqualToSize(texturePixelMapper.texturePixelSize, self.pixelSize)) {
        DYVtuberTexturePixelMapper *texturePixelMapper = [[DYVtuberTexturePixelMapper alloc]
                                                          initWithPixelSize:newSize];
        self.glTexturePixelMapper = texturePixelMapper;
    }
    
    for (MTGLRenderTask *task in self.taskArray) {
        task.renderModel.frame = self.bounds;
        task.renderModel.containerSize = self.pixelSize;
        [task updateViewPort];
    }
}

- (void)startDisplay{
    if (self.displayLink) {
        return;
    }

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderTask)];
    if (@available(iOS 10.0, *)) {
        self.displayLink.preferredFramesPerSecond = RENDER_COUNT_PER_SECOND;
    } else {
        self.displayLink.frameInterval = 1.0 / RENDER_COUNT_PER_SECOND;
    }
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stopDisplay{
    [self.displayLink invalidate];
    self.displayLink = nil;
    glClearColor(0.f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)renderTask{
    DYVtuberTexturePixelMapper *mapper = self.glTexturePixelMapper;
    if (mapper == nil) {
        return;
    }
    [self.glContext prepareForDraw];
    GLuint offscreenTexture = mapper.offscreenTexture;
    
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, offscreenTexture, 0);
    
    
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
//                              GL_COLOR_ATTACHMENT0,
//                              GL_RENDERBUFFER,
//                              self.renderBuffer);
    glClearColor(0.f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    for (MTGLRenderTask *task in self.taskArray) {
        [task render];
    }
    
//    [self.glContext.context presentRenderbuffer:GL_RENDERBUFFER];
    glFlush();
    static NSUInteger index = 0;
    if (index++ % 10 == 0) {
        index = 1;
    }
    MTGetGLError();
}

- (void)addRenderTask:(CGRect)frame withIdentifier:(NSUInteger)identifier{
    MTGLRenderModel *renderModel = [[MTGLRenderModel alloc] init];
    renderModel.identifier = identifier;
    renderModel.scale2Fit = NO;
    renderModel.containerSize = self.pixelSize;
    renderModel.frame = frame;
    renderModel.videoShader = self.glShader;
    renderModel.glContext = self.glContext;
    renderModel.contentScale = self.contentScaleFactor;

    MTGLRenderTask *task = [[MTGLRenderTask alloc] init];
    task.renderModel = renderModel;
    [task updateViewPort];
    [self.taskArray addObject:task];
}

@end
