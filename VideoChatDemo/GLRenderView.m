//
//  GLRenderView.m
//  VideoChatDemo
//
//  Created by menthu on 2019/8/25.
//  Copyright © 2019 menthu. All rights reserved.
//

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GLRenderView.h"
#import <GLKit/GLKit.h>

static NSString * const IMG_NAME = @"test1.jpg";

typedef struct{
    float Position[3];
    float TexCoord[2];
} Vertex;

@interface GLRenderView (){
    Vertex *_shaderCoordinate;
    EAGLContext     *_context;
    CAEAGLLayer     *_renderLayer;
    GLint           _backingWidth;//单位为像素
    GLint           _backingHeight;//单位为像素
    GLuint          _programHandle;
    GLuint          _renderBuffer;
    GLuint          _frameBuffer;
    GLuint          _vetexBuffer;
    GLuint          _vertexPos;
    GLuint          _texturePos;
    GLuint           _textureUniform;
    GLuint          _textureId;
}

@property (nonatomic, assign) CGFloat xOffset;
@property (nonatomic, assign) CGFloat yOffset;

@end

@implementation GLRenderView

#pragma mark - LifeCycle
+ (Class)layerClass{
    return [CAEAGLLayer class];
}

- (instancetype)init{
    if (self = [super init]) {
        [self setupView];
        [self setupOpenGL];
        [self addPanGesture];
    }
    return self;
}

- (void)addPanGesture{
    self.xOffset = self.yOffset = 0.f;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self addGestureRecognizer:panGesture];
}

- (void)panGesture:(UIPanGestureRecognizer *)gesture{
    static CGFloat xBeginPosition = 0.f;
    static CGFloat yBeginPosition = 0.f;
    CGPoint velcity = [gesture velocityInView:self];
    CGPoint panGesturePoint = [gesture locationInView:self];
    if (fabs(velcity.x) > fabs(velcity.y)) {
        if (gesture.state == UIGestureRecognizerStateBegan) {
            xBeginPosition = panGesturePoint.x;
        }else if (gesture.state == UIGestureRecognizerStateChanged){
            self.xOffset += -(panGesturePoint.x - xBeginPosition);
            xBeginPosition = panGesturePoint.x;
            [self showImg:[UIImage imageNamed:IMG_NAME]];
        }
    }else{
        if (gesture.state == UIGestureRecognizerStateBegan) {
            yBeginPosition = panGesturePoint.y;
        }else if (gesture.state == UIGestureRecognizerStateChanged){
            self.yOffset += -(panGesturePoint.y - yBeginPosition);
            yBeginPosition = panGesturePoint.y;
            [self showImg:[UIImage imageNamed:IMG_NAME]];
        }
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    static BOOL isImgShow = NO;
    if (isImgShow) {
        return;
    }
    if (_backingWidth == self.bounds.size.width * UIScreen.mainScreen.scale && _backingHeight == self.bounds.size.height * UIScreen.mainScreen.scale) {
        isImgShow = YES;
    }
    _renderLayer = (CAEAGLLayer *)self.layer;
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_renderLayer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,
                              _renderBuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    
    
    UIImage *pngImg = [UIImage imageNamed:IMG_NAME];
    [self showImg:pngImg];
}

#pragma mark - Public
- (void)showImg:(UIImage *)img{
    CGFloat imgPixelWidth = CGImageGetWidth(img.CGImage);
    CGFloat imgPixelHeight = CGImageGetHeight(img.CGImage);
    
    CGFloat vertexXMin = -1;
    CGFloat verTexYMin = -1;
    CGFloat verTexXMax = 1;
    CGFloat verTexYMax = 1;
    
    CGFloat textureXMin = 0;
    CGFloat textureYMin = 0;
    CGFloat textureXMax = 1;
    CGFloat textureYMax = 1;
    
    CGFloat widthSubtract = imgPixelWidth - _backingWidth;
    CGFloat heightSubtract = imgPixelHeight - _backingHeight;
    CGFloat space2XEdge = -widthSubtract/_backingWidth;
    CGFloat space2YEdge = -heightSubtract/_backingHeight;
    
    
    if (widthSubtract < 0) {//图像宽度 小于 屏幕宽度
        vertexXMin = -1 + space2XEdge - 2*self.xOffset/self.bounds.size.width;
        verTexXMax = vertexXMin + 2*imgPixelWidth/_backingWidth;
    }else{
        textureXMin = MIN(widthSubtract/imgPixelWidth, MAX(0, self.xOffset/imgPixelWidth));
        textureXMax = textureXMin + _backingWidth/imgPixelWidth;
    }
    
    if (heightSubtract < 0) {//图像高度 小于 屏幕高度
        verTexYMin = -1 + space2YEdge + 2*self.yOffset/self.bounds.size.height;
        verTexYMax = verTexYMin + 2*imgPixelHeight/_backingHeight;
    }else{
        textureYMin = MIN(heightSubtract/imgPixelHeight, MAX(0, -self.yOffset/imgPixelHeight));
        textureYMax = textureYMin + _backingHeight/imgPixelHeight;
    }
    
    NSLog(@"offset=[%f][%f]", _xOffset, _yOffset);
    NSLog(@"vertext=[%f][%f][%f][%f]", vertexXMin, verTexXMax, verTexYMin, verTexYMax);
//    NSLog(@"texture=[%f][%f][%f][%f]", textureXMin, textureXMax, textureYMin, textureYMax);
    
    _shaderCoordinate[0] = (Vertex){{vertexXMin, verTexYMax, 0}, {textureXMin, textureYMax}};    //左上
    _shaderCoordinate[1] = (Vertex){{vertexXMin, verTexYMin, 0}, {textureXMin, textureYMin}};   //左下
    _shaderCoordinate[2] = (Vertex){{verTexXMax, verTexYMax, 0}, {textureXMax, textureYMax}};     //右上
    _shaderCoordinate[3] = (Vertex){{verTexXMax, verTexYMin, 0}, {textureXMax, textureYMin}};    //右下
    
    GLuint textureId = [self generateTextureIdFromImg:img];
    
    glClearColor(0.f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(_programHandle);
    CGFloat yOffset = 200;
    glViewport(0, yOffset*self.contentScaleFactor, _backingWidth, _backingHeight);
    
    //设置纹理
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glUniform1i(_textureUniform, 0);
    
    //设置顶点数据
    glBindBuffer(GL_ARRAY_BUFFER, _vetexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex)*4, _shaderCoordinate, GL_STATIC_DRAW);
    
    //激活顶点
    glEnableVertexAttribArray(_vertexPos);
    glVertexAttribPointer(_vertexPos, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL + offsetof(Vertex, Position));
    
    // 设置纹理数据
    glEnableVertexAttribArray(_texturePos);
    glVertexAttribPointer(_texturePos, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL + offsetof(Vertex, TexCoord));
    
    // 开始绘制
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

#if 0
        UIImage *img2 = [UIImage imageNamed:@"test2.jpg"];
        GLuint textureId2 = [self generateTextureIdFromImg:img2];

        glViewport(_backingWidth/2, 0, _backingWidth/2, _backingHeight);
        
        //设置纹理
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, textureId2);
        glUniform1i(_textureUniform, 0);
        
        //设置顶点数据
        glBindBuffer(GL_ARRAY_BUFFER, _vetexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex)*4, _shaderCoordinate, GL_STATIC_DRAW);
        
        //激活顶点
        glEnableVertexAttribArray(_vertexPos);
        glVertexAttribPointer(_vertexPos, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL + offsetof(Vertex, Position));
        
        // 设置纹理数据
        glEnableVertexAttribArray(_texturePos);
        glVertexAttribPointer(_texturePos, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL + offsetof(Vertex, TexCoord));
        
        // 开始绘制
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
#endif
    
    
    // 将绑定的渲染缓存呈现到屏幕上
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (GLuint)generateTextureIdFromImg:(UIImage *)image{
    // 将 UIImage 转换为 CGImageRef
    CGImageRef cgImageRef = [image CGImage];
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    // 绘制图片
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);

    glBindTexture(GL_TEXTURE_2D, _textureId);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData); // 将图片数据写入纹理缓存
    
    // 设置如何把纹素映射成像素
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    // 解绑
    glBindTexture(GL_TEXTURE_2D, 0);
    
    // 释放内存
    CGContextRelease(context);
    free(imageData);
    
    return _textureId;
}

#pragma mark - Private
- (void)setupView{
    _shaderCoordinate = malloc(sizeof(Vertex) * 4);//根据现实的图片动态更改数据
    self.backgroundColor = UIColor.orangeColor;
    self.contentScaleFactor = UIScreen.mainScreen.scale;
}

- (void)setupOpenGL{
    //初始化OpenGL上下文
    [self setupOpenGLContext];

    //绑定Frame和RenderBuffer
    [self setupFrameBufferAndRenderBuffer];
    
    //加载shader
    [self loadShader];
    
    //初始化buffer
    [self setupBuffer];
}

- (void)setupOpenGLContext{
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_context];
}

- (void)setupFrameBufferAndRenderBuffer{
    glGenRenderbuffers(1, &_renderBuffer);
    glGenFramebuffers(1, &_frameBuffer);
}

- (void)setupBuffer{
    // 创建顶点缓存
    glGenBuffers(1, &_vetexBuffer);
    
    // 生成纹理
    glGenTextures(1, &_textureId);
}

- (void)loadShader{
    //1
    GLuint vertexShaderHandle   = [self compileShader:@"vertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShaderHandle = [self compileShader:@"fragment" withType:GL_FRAGMENT_SHADER];
    
    //2
    _programHandle = glCreateProgram();
    glAttachShader(_programHandle, vertexShaderHandle);
    glAttachShader(_programHandle, fragmentShaderHandle);
    glDeleteShader(vertexShaderHandle);
    glDeleteShader(fragmentShaderHandle);
    glLinkProgram(_programHandle);
    
    //3
    GLint linkSuccess;
    glGetProgramiv(_programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    //4
    glUseProgram(_programHandle);

    //5
    _vertexPos = glGetAttribLocation(_programHandle, "Position");
    _texturePos = glGetAttribLocation(_programHandle, "TextureCoords");
    _textureUniform = glGetUniformLocation(_programHandle, "Texture");
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
    //1
    NSError* error = nil;
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    //2
    GLuint shaderHandle = glCreateShader(shaderType);
    
    //3
    const char* shaderStringUTF8 = [shaderString UTF8String];
    
    int shaderStringLength = (int)[shaderString length];
    
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    //4
    glCompileShader(shaderHandle);
    
    //5
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}

@end
