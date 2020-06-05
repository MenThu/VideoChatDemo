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

typedef struct{
    float Position[3];
    float TexCoord[2];
} Vertex;

@interface MTGLRenderTask (){
    Vertex *_shaderCoordinate;
}

@property (nonatomic, assign) GLuint textureId;
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
    MTGetGLError();
    _shaderCoordinate = malloc(sizeof(Vertex) * 4);//根据现实的图片动态更改数据
    NSAssert(_shaderCoordinate != NULL, @"");
}

- (void)dealloc{
    glDeleteTextures(1, &self->_textureId);
    if (_shaderCoordinate != NULL) {
        free(_shaderCoordinate);
        _shaderCoordinate = NULL;
    }
}

- (void)setRenderModel:(MTGLRenderModel *)renderModel{
    _renderModel = renderModel;
    if (CGSizeEqualToSize(renderModel.containerSize, CGSizeZero)) {
        return;
    }
    
    [self updateViewPort];
    
    [renderModel.glContext useThisContext];
    
    if (self->_textureId <= 0) {
        glGenTextures(1, &self->_textureId);
        MTGetGLError();
    }
    NSAssert(self.textureId > 0, @"");
    
    //将img上传到OpenGL ES的纹理ID去
    UIImage *img = [UIImage imageNamed:renderModel.imgName];
    [self uploadImg:img toTextureId:self.textureId];
    
    CGFloat renderBufferWidthDivideHeight = self.viewPort.size.width/self.viewPort.size.height;
    CGFloat imgWidthDivideHeight = img.size.width/img.size.height;
    CGFloat minus = imgWidthDivideHeight - renderBufferWidthDivideHeight;
    if (renderModel.scaleImg2Fit) {//顶点坐标不修改
        CGFloat texturexMinus = 0;
        CGFloat textureyMinus = 0;
        if (minus > 0) {//裁剪x轴
            texturexMinus = (img.size.width - renderBufferWidthDivideHeight*img.size.height)/(2*img.size.width);
        }else{//裁剪y轴
            textureyMinus = (img.size.height - img.size.width/renderBufferWidthDivideHeight)/(2*img.size.height);
        }
        _shaderCoordinate[0] = (Vertex){{-1, 1, 0}, {texturexMinus, 1-textureyMinus}};  //左上
        _shaderCoordinate[1] = (Vertex){{-1, -1, 0}, {texturexMinus, textureyMinus}};   //左下
        _shaderCoordinate[2] = (Vertex){{1, 1, 0}, {1-texturexMinus, 1-textureyMinus}}; //右上
        _shaderCoordinate[3] = (Vertex){{1, -1, 0}, {1-texturexMinus, textureyMinus}};  //右下
    }else{//纹理坐标不修改
        CGFloat vertextxMinus = 0;
        CGFloat vertextyMinus = 0;
        if (minus > 0) {//上下留黑边
            vertextyMinus = (self.viewPort.size.height - (self.viewPort.size.width/imgWidthDivideHeight))/self.viewPort.size.height;
        }else{//左右留黑边
            vertextxMinus = (self.viewPort.size.width - imgWidthDivideHeight*self.viewPort.size.height)/self.viewPort.size.width;
        }
        _shaderCoordinate[0] = (Vertex){{-1+vertextxMinus, 1-vertextyMinus, 0}, {0, 1}};    //左上
        _shaderCoordinate[1] = (Vertex){{-1+vertextxMinus, -1+vertextyMinus, 0}, {0, 0}};   //左下
        _shaderCoordinate[2] = (Vertex){{1-vertextxMinus, 1-vertextyMinus, 0}, {1, 1}};     //右上
        _shaderCoordinate[3] = (Vertex){{1-vertextxMinus, -1+vertextyMinus, 0}, {1, 0}};    //右下
    }
}

- (void)updateViewPort{
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
    
    //设置纹理
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureId);
    glUniform1i(self.renderModel.imgShader.textureUniform, 0);
    MTGetGLError();
    
    //设置顶点数据
    glBindBuffer(GL_ARRAY_BUFFER, self.renderModel.glContext.vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex)*4, _shaderCoordinate, GL_STATIC_DRAW);
    MTGetGLError();
    
    //设置index数据
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.renderModel.glContext.indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    MTGetGLError();
    
    //设置顶点坐标
    glEnableVertexAttribArray(self.renderModel.imgShader.vertexPos);
    glVertexAttribPointer(self.renderModel.imgShader.vertexPos, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL + offsetof(Vertex, Position));
    MTGetGLError();
    
    //设置纹理坐标
    glEnableVertexAttribArray(self.renderModel.imgShader.texturePos);
    glVertexAttribPointer(self.renderModel.imgShader.texturePos, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), NULL + offsetof(Vertex, TexCoord));
    MTGetGLError();
    
    //绘画
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, 0);
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


@implementation MTGLRenderModel @end
