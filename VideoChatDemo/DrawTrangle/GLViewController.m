//
//  GLViewController.m
//  VideoChatDemo
//
//  Created by menthu on 2019/9/2.
//  Copyright © 2019 menthu. All rights reserved.
//

#import "GLViewController.h"
#import <OpenGLES/ES2/glext.h>

static GLfloat vertices[] = {
    0.0f,  0.5f,  0, 1, 0, 0,
    -0.5f, -0.5f,  0, 0, 1, 0,
    0.5f, -0.5f,  0, 0, 0, 1,
};

@interface GLViewController (){
//    GLuint _program;
//    GLuint _vbo;
//    GLuint _vao;
//    GLKMatrix4 _transformMatrix;
}

@property (assign, nonatomic) GLuint program;
@property (assign, nonatomic) GLuint vbo;
@property (assign, nonatomic) GLuint vao;
@property (assign, nonatomic) GLKMatrix4 transformMatrix;

@end

@implementation GLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupGLContext];
    [self setupShader];
    [self genVBO];
    [self genVAO];
    self.view.backgroundColor = UIColor.whiteColor;
    _transformMatrix = GLKMatrix4Identity;
}

- (void)setupGLContext{
    // 初始化EAGLContext
    GLKView *view = (GLKView *)self.view;
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    // 设置帧率为60fps
    self.preferredFramesPerSecond = 60;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    [EAGLContext setCurrentContext:view.context];
}

- (void)setupShader {
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"TriangleVertex" ofType:@"glsl"];
    NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"TriangleFragment" ofType:@"glsl"];
    
    NSString *vertexContext = [NSString stringWithContentsOfFile:vertexShaderPath encoding:NSUTF8StringEncoding error:nil];
    NSString *fragmentContext = [NSString stringWithContentsOfFile:fragmentShaderPath encoding:NSUTF8StringEncoding error:nil];
    
    createProgram(vertexContext.UTF8String, fragmentContext.UTF8String, &_program);
}

- (void)genVBO{
    // 使用glGenBuffers函数和一个缓冲ID生成一个VBO对象
    glGenBuffers(1, &_vbo);
    
    // 使用glBindBuffer函数把新创建的缓冲绑定到GL_ARRAY_BUFFER目标上
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    
    // 调用glBufferData函数，它会把之前定义的顶点数据复制到缓冲的内存中
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
}

- (void)genVAO{
    glGenVertexArraysOES(1, &_vao);

    // 绑定vao
    glBindVertexArrayOES(_vao);

    // 把顶点数组复制到缓冲中供OpenGL ES使用
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);

    // 激活顶点属性
    GLuint positionAttribLocation = glGetAttribLocation(_program, "position");
    glEnableVertexAttribArray(positionAttribLocation);

    GLuint colorAttribLocation = glGetAttribLocation(_program, "color");
    glEnableVertexAttribArray(colorAttribLocation);

    glVertexAttribPointer(positionAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), NULL);
    glVertexAttribPointer(colorAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), NULL + 3 * sizeof(GLfloat));

    glBindVertexArrayOES(0);
}

#pragma mark - DrawTriangle
- (void)update {
    static GLfloat changeValue= 0.f;
    NSTimeInterval deltaTime = self.timeSinceLastUpdate;
    changeValue += deltaTime;
    GLfloat elValue = sinf(changeValue);
//    _transformMatrix = GLKMatrix4Make(1.0, 0.0,           0.0,          0.0,
//                                      0.0, cos(elValue), -sin(elValue), 0.0,
//                                      0.0, sin(elValue),  cos(elValue), 0.0,
//                                      0.0, 0.0,           0.0,          1.0);
    
//    _transformMatrix = GLKMatrix4Make(cos(elValue),-sin(elValue), 0.0, 0.0,
//                                     sin(elValue), cos(elValue), 0.0, 0.0,
//                                     0.0,           0.0,         1.0, 0.0,
//                                     0.0,           0.0,         0.0, 1.0);
    
    _transformMatrix = GLKMatrix4MakeTranslation(elValue, 0, 0);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    // 清除缓存
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1.0, 1.0, 1.0, 1.0);
    
    // 启用这个着色器程序
    glUseProgram(_program);
    
    glBindVertexArrayOES(_vao);
    
//    GLKMatrix4 tempMatrix = GLKMatrix4MakeScale(1, -1, 1.0);
//    GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(90) , 0.0, 0.0, 1.0);
    GLuint transformUniformLocation = glGetUniformLocation(_program, "transform");
    glUniformMatrix4fv(transformUniformLocation, 1, 0, _transformMatrix.m);
    
    // 绘制
    glDrawArrays(GL_TRIANGLES, 0,3);
}

#pragma mark - Prepare Shaders
bool createProgram(const char *vertexShader, const char *fragmentShader, GLuint *pProgram) {
    GLuint program, vertShader, fragShader;
    // Create shader program.
    program = glCreateProgram();
    
    const GLchar *vssource = (GLchar *)vertexShader;
    const GLchar *fssource = (GLchar *)fragmentShader;
    
    if (!compileShader(&vertShader,GL_VERTEX_SHADER, vssource)) {
        printf("Failed to compile vertex shader");
        return false;
    }
    
    if (!compileShader(&fragShader,GL_FRAGMENT_SHADER, fssource)) {
        printf("Failed to compile fragment shader");
        return false;
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Link program.
    if (!linkProgram(program)) {
        printf("Failed to link program: %d", program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program) {
            glDeleteProgram(program);
            program = 0;
        }
        return false;
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
    
    *pProgram = program;
    printf("Effect build success => %d \n", program);
    return true;
}


bool compileShader(GLuint *shader, GLenum type, const GLchar *source) {
    GLint status;
    
    if (!source) {
        printf("Failed to load vertex shader");
        return false;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    
#if Debug
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        printf("Shader compile log:\n%s", log);
        printf("Shader: \n %s\n", source);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return false;
    }
    
    return true;
}

bool linkProgram(GLuint prog) {
    GLint status;
    glLinkProgram(prog);
    
#if Debug
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        printf("Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return false;
    }
    
    return true;
}

bool validateProgram(GLuint prog) {
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        printf("Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return false;
    }
    
    return true;
}

@end
