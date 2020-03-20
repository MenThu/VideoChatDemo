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
#import "VideoFrame.h"
#import <GLKit/GLKit.h>

typedef struct{
    float Position[3];
    float TexCoord[2];
} Vertex;

Vertex initVertices[] = {
    {{-1, 1, 0},{0,1}},     //顶点左上  纹理左上
    {{1, 1, 0},{1, 1}},     //顶点右上  纹理右上
    {{1, -1, 0},{1, 0}},    //顶点右下  纹理右下
    {{-1, -1, 0},{0, 0}},   //顶点左下  纹理左下
};

GLubyte const Indices[] = {
    0, 1, 2,
    0, 3, 2,
};

//Vertex initVertices[] = {
//    {{-1, 1, 0},    {0, 0}}, // 顶点左上    纹理左下
//    {{-1, -1, 0},   {0, 1}}, // 顶点左下    纹理左上
//    {{1, -1, 0},    {1, 1}}, // 顶点右下    纹理右上
//    {{1, 1, 0},     {1, 0}}, // 顶点右上    纹理右下
//};

//GLubyte const Indices[] = {
//    0, 1, 2,
//    0, 3, 2,
//};

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
- (instancetype)init{
    if (self = [super init]) {
        self.backgroundColor = UIColor.orangeColor;
        [self setupView];
        [self setupOpenGL];
    }
    return self;
}

+ (Class)layerClass{
    return [CAEAGLLayer class];
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
}

#pragma mark - Private
- (void)setupView{
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
    
    glGenTextures(1, &_textureY);
//    glGenTextures(1, &_textureU);
//    glGenTextures(1, &_textureV);
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
    _vertexPos = glGetAttribLocation(_programHandle, "position");
    _texturePos = glGetAttribLocation(_programHandle, "textureCoordinate");
    _sampleY = glGetUniformLocation(_programHandle, "SamplerY");
    _sampleU = glGetUniformLocation(_programHandle, "SamplerU");
    _sampleV = glGetUniformLocation(_programHandle, "SamplerV");
    _modelTransform = glGetUniformLocation(_programHandle, "modelTransform");
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

#pragma mark - DrawVideo
- (void)didCaptureVideoFrame:(VideoFrame *)frame{
    glClearColor(0.f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //I420 -> sampleY sampleU sampleV
    GLint sampleY = [self generateTexureFromYUVImgData:frame->_imgData width:frame.imgWidth height:frame.imgHeight indexOfTexture:0];
//    GLint sampleU = [self generateTexureFromYUVImgData:frame->_imgData+frame.imgWidth*frame.imgHeight width:(int)frame.imgWidth/2 height:(int)frame.imgHeight/2 indexOfTexture:1];
//    GLint sampleV = [self generateTexureFromYUVImgData:frame->_imgData+frame.imgWidth*frame.imgHeight*4/5 width:(int)frame.imgWidth/2 height:(int)frame.imgHeight/2 indexOfTexture:2];

    glUseProgram(_programHandle);
    
    //绕Z轴旋转
    GLKMatrix4 modelMatrix = GLKMatrix4MakeRotation(frame.imgAngle, 0, 0, 1);
    
    //XY轴上下翻转
    modelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeScale(frame.needMirror ? -1 : 1, -1, 1), modelMatrix);
    
    glUniformMatrix4fv(_modelTransform, 1, 0, modelMatrix.m);

    //对shader的纹理进行赋值
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, sampleY);
    glUniform1i(_sampleY, 0);

//    glActiveTexture(GL_TEXTURE1);
//    glBindTexture(GL_TEXTURE_2D, sampleU);
//    glUniform1i(_sampleU, 1);
//
//    glActiveTexture(GL_TEXTURE2);
//    glBindTexture(GL_TEXTURE_2D, sampleV);
//    glUniform1i(_sampleV, 2);
    
    //对shader的顶点属性和纹理坐标属性
    glBindBuffer(GL_ARRAY_BUFFER, _vetexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    glVertexAttribPointer(_vertexPos, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, Position));
    glEnableVertexAttribArray(_vertexPos);
    glVertexAttribPointer(_texturePos, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, TexCoord));
    glEnableVertexAttribArray(_texturePos);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, 0);
//    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    if ([EAGLContext currentContext] == _context) {
        [_context presentRenderbuffer:GL_RENDERBUFFER];
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

- (GLuint)generateTexureFromYUVImgData:(Byte *)imgData width:(int)imgWidth height:(int)imgHeight indexOfTexture:(int)index{
    GLuint textureID;
    if (index == 0) {//y
        textureID = _textureY;
    }else if (index == 1){//u
        textureID = _textureU;
    }else{//v
        textureID = _textureV;
    }
    
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, imgWidth, imgHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, imgData); // 将图片数据写入纹理缓存
    
    glBindTexture(GL_TEXTURE_2D, 0);
    return textureID;
}


@end
