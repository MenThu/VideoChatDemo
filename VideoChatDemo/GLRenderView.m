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
    float position[3];
    float rgbClolor[3];
} Vertex;

Vertex initVertices[] = {
    {{-0.5, 0, 0},{0,1,1}},   //顶点左上
    {{0.5, 0.5, 0},{1, 1, 0}},  //顶点右上
    {{0.5, -0.5, 0},{1, 0,1}},  //顶点右下
};

GLubyte const Indices[] = {
    0, 1, 2,
    0, 3, 2,
};

@interface GLRenderView (){
    EAGLContext     *_context;
    CAEAGLLayer     *_renderLayer;
    GLint           _backingWidth;//单位为像素
    GLint           _backingHeight;//单位为像素
    
    GLuint          _programHandle;
    
    GLuint          _renderBuffer;
    GLuint          _frameBuffer;
    GLuint          _indexBuffer;
    GLuint          _vetexBuffer;
    
    GLuint          _vertexPos;
    GLuint          _texturePos;
    
    
    GLuint           _textureY;
    GLuint           _textureU;
    GLuint           _textureV;
    GLuint          _sampleY;
    GLuint          _sampleU;
    GLuint          _sampleV;
    GLuint          _modelTransform;
    
}

@property (assign, nonatomic) BOOL isOpenGLSetup;

@end

@implementation GLRenderView

#pragma mark - LifeCycle
+ (Class)layerClass{
    return [CAEAGLLayer class];
}

- (instancetype)init{
    if (self = [super init]) {
        self.backgroundColor = UIColor.whiteColor;
        [self setupView];
        [self setupOpenGL];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    _renderLayer = (CAEAGLLayer *)self.layer;
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_renderLayer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    [self drawPicture];
}

#pragma mark - Private
- (void)setupView{
    CAEAGLLayer *glLayer = (CAEAGLLayer *)self.layer;
    /*
     *  kEAGLDrawablePropertyRetainedBacking:The key specifying whether the drawable surface retains its contents after displaying them.
     *  kEAGLDrawablePropertyColorFormat:The key specifying the internal color buffer format for the drawable surface.
     */
    glLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking : @(YES), // retained unchange
                                   kEAGLDrawablePropertyColorFormat     : kEAGLColorFormatRGBA8 // 32-bits Color
                                   };
    
    glLayer.contentsScale = [UIScreen mainScreen].scale;
    glLayer.opaque = YES;
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
    glBindBuffer(GL_ARRAY_BUFFER, _vetexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(initVertices), initVertices, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    //设置索引缓冲区
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
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
    GLuint positionAttribLocation = glGetAttribLocation(_programHandle, "position");
    glEnableVertexAttribArray(positionAttribLocation);
    GLuint colorAttribLocation = glGetAttribLocation(_programHandle, "color");
    glEnableVertexAttribArray(colorAttribLocation);
}

- (void)drawPicture{
    [EAGLContext setCurrentContext:_context];
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,
                              _renderBuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    glClearColor(0.3, 0.3, 0, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram(_programHandle);
    

    //    [self drawTriangleWithCPUData];
    [self drawTriangleWithVBOData];

    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)drawTriangleWithCPUData{
    GLuint positionAttribLocation = glGetAttribLocation(_programHandle, "position");
    glEnableVertexAttribArray(positionAttribLocation);
    GLuint colorAttribLocation = glGetAttribLocation(_programHandle, "color");
    glEnableVertexAttribArray(colorAttribLocation);
    glVertexAttribPointer(positionAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (char *)initVertices);
    glVertexAttribPointer(colorAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (char *)initVertices + 3 * sizeof(GLfloat));
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

- (void)drawTriangleWithVBOData{
    GLuint positionAttribLocation = glGetAttribLocation(_programHandle, "position");
    glEnableVertexAttribArray(positionAttribLocation);
    GLuint colorAttribLocation = glGetAttribLocation(_programHandle, "color");
    glEnableVertexAttribArray(colorAttribLocation);
    //指定顶点数据来源
    glBindBuffer(GL_ARRAY_BUFFER, _vetexBuffer);
    glVertexAttribPointer(positionAttribLocation, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, position));
    glVertexAttribPointer(colorAttribLocation, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, rgbClolor));
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

- (void)drawTriangleWithVEOData{
    
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
