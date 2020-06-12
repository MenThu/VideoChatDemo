//
//  MTGLRenderTask.m
//  VideoChatDemo
//
//  Created by menthu on 2020/5/8.
//  Copyright © 2020 menthu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import "MTGLRenderTask.h"
#import "MTGLHead.h"

static const GLubyte indices[] = {0, 1, 2, 2, 3, 1};
static const NSInteger YUV_PLANAR_COUNT = 3;

typedef struct{
    float Position[3];
    float TexCoord[2];
} Vertex;

@interface MTGLRenderTask (){
    Vertex *_shaderCoordinate;
}

@property (nonatomic, assign) GLuint *yuvTextureId;
@property (nonatomic, assign) CGRect viewPort;

@end

@implementation MTGLRenderTask

- (instancetype)init{
    if (self = [super init]) {
        [self initTask];
    }
    return self;
}

- (void)initTask{
    size_t shaderSize = sizeof(Vertex) * 4;
    _shaderCoordinate = malloc(shaderSize);//根据现实的图片动态更改数据
    NSAssert(_shaderCoordinate != NULL, @"");
    bzero(_shaderCoordinate, shaderSize);
    
    size_t yuvTextureSize = sizeof(GLuint) * YUV_PLANAR_COUNT;
    self.yuvTextureId = (GLuint *)malloc(yuvTextureSize);
    NSAssert(self.yuvTextureId != NULL, @"");
    bzero(self.yuvTextureId, yuvTextureSize);
}

- (void)dealloc{
    if (self.yuvTextureId != NULL) {
        glDeleteTextures(YUV_PLANAR_COUNT, self.yuvTextureId);
        MTGetGLError();
        free(self.yuvTextureId);
        self.yuvTextureId = NULL;
    }
    if (_shaderCoordinate != NULL) {
        free(_shaderCoordinate);
        _shaderCoordinate = NULL;
    }
}

- (void)setFrame:(VideoFrame *)frame{
    if (self.yuvTextureId == NULL ||
        frame.format != VideoFormatI420 ||
        CGSizeEqualToSize(self.renderModel.containerSize, CGSizeZero)) {
        return;
    }
    _frame = frame;
    
    [self.renderModel.glContext useThisContext];
    
    
    unsigned char *yPlane = frame.yuvBuffer;
    unsigned char *uPlane = frame.yuvBuffer + frame.width*frame.height;
    unsigned char *vPlane = frame.yuvBuffer + frame.width*frame.height*5/4;//因为宽度和高度都是2的倍数，所以这里一定可以整除
    [self uploadData:yPlane width:(int)frame.width height:(int)frame.height toTextureId:self.yuvTextureId[0]];
    [self uploadData:uPlane width:(int)frame.width/2 height:(int)frame.height/2 toTextureId:self.yuvTextureId[1]];
    [self uploadData:vPlane width:(int)frame.width/2 height:(int)frame.height/2 toTextureId:self.yuvTextureId[2]];
    
    
    CGFloat width = frame.width;
    CGFloat height = frame.height;
    if (frame.rotation == VideoRotation_90 ||
        frame.rotation == VideoRotation_270) {
        width = frame.height;
        height = frame.width;
    }
    
    CGFloat renderBufferWidthDivideHeight = self.viewPort.size.width/self.viewPort.size.height;
    CGFloat imgWidthDivideHeight = (CGFloat)width/height;
    CGFloat minus = imgWidthDivideHeight - renderBufferWidthDivideHeight;
    if (self.renderModel.scale2Fit) {//顶点坐标不修改
        CGFloat texturexMinus = 0;
        CGFloat textureyMinus = 0;
        if (minus > 0) {//裁剪x轴
            textureyMinus = (width - renderBufferWidthDivideHeight*height)/(2*width);
        }else{//裁剪y轴
            texturexMinus = (height - width/renderBufferWidthDivideHeight)/(2*height);
        }
        _shaderCoordinate[0] = (Vertex){{-1, 1, 0}, {texturexMinus, 1-textureyMinus}};  //左上
        _shaderCoordinate[1] = (Vertex){{-1, -1, 0}, {texturexMinus, textureyMinus}};   //左下
        _shaderCoordinate[2] = (Vertex){{1, 1, 0}, {1-texturexMinus, 1-textureyMinus}}; //右上
        _shaderCoordinate[3] = (Vertex){{1, -1, 0}, {1-texturexMinus, textureyMinus}};  //右下
    }else{//纹理坐标不修改
        CGFloat vertextxMinus = 0;
        CGFloat vertextyMinus = 0;
        if (minus > 0) {//上下留黑边，但后续需要旋转90度，所以这里裁剪的是X轴
            vertextxMinus = (self.viewPort.size.height - (self.viewPort.size.width/imgWidthDivideHeight))/self.viewPort.size.height;
        }else{//左右留黑边
            vertextyMinus = (self.viewPort.size.width - imgWidthDivideHeight*self.viewPort.size.height)/self.viewPort.size.width;
        }
        _shaderCoordinate[0] = (Vertex){{-1+vertextxMinus, 1-vertextyMinus, 0}, {0, 1}};    //左上
        _shaderCoordinate[1] = (Vertex){{-1+vertextxMinus, -1+vertextyMinus, 0}, {0, 0}};   //左下
        _shaderCoordinate[2] = (Vertex){{1-vertextxMinus, 1-vertextyMinus, 0}, {1, 1}};     //右上
        _shaderCoordinate[3] = (Vertex){{1-vertextxMinus, -1+vertextyMinus, 0}, {1, 0}};    //右下
    }
}

- (void)setRenderModel:(MTGLRenderModel *)renderModel{
    _renderModel = renderModel;
    [renderModel.glContext useThisContext];
    if (self.yuvTextureId != NULL &&
        *(self.yuvTextureId) <= 0 &&
        *(self.yuvTextureId+1) <= 0 &&
        *(self.yuvTextureId+2) <= 0) {
        glGenTextures(YUV_PLANAR_COUNT, self.yuvTextureId);
        MTGetGLError();
    }else{
        MTGetGLError();
    }
}

- (void)uploadData:(unsigned char *)data width:(int)width height:(int)height toTextureId:(GLuint)textureId{
    if (textureId <= 0) {
        return;
    }
    
    if (data == NULL) {
        return;
    }
    
    glBindTexture(GL_TEXTURE_2D, textureId);
    MTGetGLError();
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    MTGetGLError();
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, data);
    MTGetGLError();
    
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)updateViewPort{
    if (CGSizeEqualToSize(self.renderModel.containerSize, CGSizeZero)) {
        return;
    }
    CGFloat x = self.renderModel.frame.origin.x * self.renderModel.contentScale;
    CGFloat width = self.renderModel.frame.size.width * self.renderModel.contentScale;
    CGFloat height = self.renderModel.frame.size.height * self.renderModel.contentScale;
    CGFloat y = self.renderModel.containerSize.height - self.renderModel.frame.origin.y * self.renderModel.contentScale - height;
    self.viewPort = CGRectMake(x, y, width, height);
}

- (void)render{
    [self updateViewPort];
    
    glViewport(self.viewPort.origin.x,
               self.viewPort.origin.y,
               self.viewPort.size.width,
               self.viewPort.size.height);
    
    //绕Z轴顺时针旋转90度
    GLKMatrix4 modelMatrix = GLKMatrix4MakeRotation(M_PI_2, 0, 0, 1);
    //X轴翻转为镜像效果
    //Y轴翻转为解决纹理坐标与屏幕坐标Y轴相反问题
    modelMatrix = GLKMatrix4Multiply(GLKMatrix4MakeScale(self.frame.needMirror ? -1 : 1, -1, 1), modelMatrix);
    //设置顶点统一变量
    glUniformMatrix4fv(self.renderModel.videoShader.modelTransform, 1, 0, modelMatrix.m);
    
    //设置纹理
    for (int i = 0; i < YUV_PLANAR_COUNT; i ++) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, self.yuvTextureId[i]);
        glUniform1i(self.renderModel.videoShader.textureUniforms[i], i);
        MTGetGLError();
    }
    
    //设置顶点数据
    glBindBuffer(GL_ARRAY_BUFFER, self.renderModel.glContext.vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex)*4, _shaderCoordinate, GL_STATIC_DRAW);
    MTGetGLError();
    
    //设置index数据
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.renderModel.glContext.indexBuffer);
//    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
//    MTGetGLError();
    
    //设置顶点坐标
    glEnableVertexAttribArray(self.renderModel.videoShader.vertexPos);
    glVertexAttribPointer(self.renderModel.videoShader.vertexPos, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL + offsetof(Vertex, Position));
    MTGetGLError();
    
    //设置纹理坐标
    glEnableVertexAttribArray(self.renderModel.videoShader.texturePos);
    glVertexAttribPointer(self.renderModel.videoShader.texturePos, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL + offsetof(Vertex, TexCoord));
    MTGetGLError();
    
    //绘画
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//    gldraw(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, 0);
    MTGetGLError();
    
    //解除绑定
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    MTGetGLError();
}

- (void)uploadImg:(UIImage *)image toTextureId:(GLuint)textureId{
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

    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData); // 将图片数据写入纹理缓存
    MTGetGLError();
    
    // 设置如何把纹素映射成像素
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    // 解绑
    glBindTexture(GL_TEXTURE_2D, 0);
    MTGetGLError();
    
    // 释放内存
    CGContextRelease(context);
    free(imageData);
}

@end


@implementation MTGLRenderModel

- (instancetype)init{
    if (self = [super init]) {
        self.containerSize = CGSizeZero;
        self.scale2Fit = NO;
    }
    return self;
}

@end
