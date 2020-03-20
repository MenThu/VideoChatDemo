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
}

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
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)layoutSubviews{
    [super layoutSubviews];
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
    
    static NSInteger index = 1;
    [self showImg:[UIImage imageNamed:[NSString stringWithFormat:@"test%d.jpg", (int)index++]] isFull:YES];
    if (index > 5) index = 1;
}

#pragma mark - Public
- (void)showImg:(UIImage *)img isFull:(BOOL)isFull{
    CGFloat renderBufferWidthDivideHeight = _backingWidth/(CGFloat)_backingHeight;
    CGFloat imgWidthDivideHeight = img.size.width/img.size.height;
    CGFloat minus = imgWidthDivideHeight - renderBufferWidthDivideHeight;
    if (isFull) {//全屏展示，裁剪图片
        CGFloat texturexMinus = 0;
        CGFloat textureyMinus = 0;
        if (minus > 0) {//裁剪x轴
            texturexMinus = (img.size.width - renderBufferWidthDivideHeight*img.size.height)/(2*img.size.width);
        }else{//裁剪y轴
            textureyMinus = (img.size.height - img.size.width/renderBufferWidthDivideHeight)/(2*img.size.height);
        }
        _shaderCoordinate[0] = (Vertex){{-1, 1, 0}, {texturexMinus, 1-textureyMinus}};    //左上
        _shaderCoordinate[1] = (Vertex){{-1, -1, 0}, {texturexMinus, textureyMinus}};   //左下
        _shaderCoordinate[2] = (Vertex){{1, 1, 0}, {1-texturexMinus, 1-textureyMinus}};     //右上
        _shaderCoordinate[3] = (Vertex){{1, -1, 0}, {1-texturexMinus, textureyMinus}};    //右下
    }else{//黑边，修改顶点坐标
        CGFloat vertextxMinus = 0;
        CGFloat vertextyMinus = 0;
        if (minus > 0) {//上下留黑边
            vertextyMinus = (_backingHeight - (_backingWidth/imgWidthDivideHeight))/_backingHeight;
        }else{//左右留黑边
            vertextxMinus = (_backingWidth - imgWidthDivideHeight*_backingHeight)/_backingWidth;
        }
        _shaderCoordinate[0] = (Vertex){{-1+vertextxMinus, 1-vertextyMinus, 0}, {0, 1}};    //左上
        _shaderCoordinate[1] = (Vertex){{-1+vertextxMinus, -1+vertextyMinus, 0}, {0, 0}};   //左下
        _shaderCoordinate[2] = (Vertex){{1-vertextxMinus, 1-vertextyMinus, 0}, {1, 1}};     //右上
        _shaderCoordinate[3] = (Vertex){{1-vertextxMinus, -1+vertextyMinus, 0}, {1, 0}};    //右下
    }
//    if (widthDivideHeight > 1) {//裁剪width边，拉伸height边
//
//    }else{
//
//    }
    
//    CGFloat y = ((CGFloat)_backingHeight - _backingWidth) / _backingHeight;
//    2.0f*   (_backingHeight*2);
    
//    _shaderCoordinate[0] = (Vertex){{-1, 1-y, 0}, {0, 1}};    //左上
//    _shaderCoordinate[1] = (Vertex){{-1, -1+y, 0}, {0, 0}};   //坐下
//    _shaderCoordinate[2] = (Vertex){{1, 1-y, 0}, {1, 1}};     //右上
//    _shaderCoordinate[3] = (Vertex){{1, -1+y, 0}, {1, 0}};    //右下
    
    GLuint textureId = [self generateTextureIdFromImg:img];
    
    glUseProgram(_programHandle);
    glViewport(0, 0, _backingWidth, _backingHeight);
    
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

    // 生成纹理
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
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
    
    return textureID;
}

#pragma mark - Private
- (void)setupView{
    _shaderCoordinate = malloc(sizeof(Vertex) * 4);//根据现实的图片动态更改数据
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
