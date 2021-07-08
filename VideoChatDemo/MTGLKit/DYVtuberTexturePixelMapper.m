//
//  DYVtuberTexturePixelMapper.m
//  VideoChatDemo
//
//  Created by menthu on 2021/7/7.
//  Copyright © 2021 menthu. All rights reserved.
//

#import "DYVtuberTexturePixelMapper.h"
#import <UIKit/UIGeometry.h>

@interface DYVtuberTexturePixelMapper (){
    CVOpenGLESTextureRef _CVGLTexture;
    CVOpenGLESTextureCacheRef _CVGLTextureCache;
}

@property (nonatomic, assign, readwrite) CGSize texturePixelSize;
@property (nonatomic, assign, readwrite) GLuint offscreenTexture;
@property (nonatomic, assign, readwrite) CVPixelBufferRef pixelBuffer;

@end

@implementation DYVtuberTexturePixelMapper

- (instancetype)initWithPixelSize:(CGSize)texturePixelSize{
    if (self = [super init]) {
        NSLog(@"CreateMapper PixelSize = [%@]", NSStringFromCGSize(texturePixelSize));
        self.texturePixelSize = texturePixelSize;
        [self configTextureBaseOnPixel];
    }
    return self;
}

- (void)configTextureBaseOnPixel{
    CGSize textureSize = self.texturePixelSize;
    
    CFDictionaryRef empty;
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    //CFDictionarySetValue(attrs, kCVPixelBufferOpenGLCompatibilityKey, @YES);
    CVReturn ret = CVPixelBufferCreate(kCFAllocatorDefault,
                                       textureSize.width,
                                       textureSize.height,
                                       kCVPixelFormatType_32BGRA,
                                       attrs,
                                       &_pixelBuffer);
    if (ret != kCVReturnSuccess) {
        NSLog(@"Failed to create CVPixelBuffer");
        return;
    }
    
    EAGLContext *currentContext = EAGLContext.currentContext;

    // 1. Create an OpenGL ES CoreVideo texture cache from the pixel buffer.
    ret = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, currentContext, nil, &_CVGLTextureCache);
    if (ret != kCVReturnSuccess) {
        NSLog(@"Failed to create OpenGL ES Texture Cache");
        return;
    }
    
    
    
    //{ kCVPixelFormatType_32BGRA,              MTLPixelFormatBGRA8Unorm,      GL_RGBA,           GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8_REV }

    // 2. Create a CVPixelBuffer-backed OpenGL ES texture image from the texture cache.
    ret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _CVGLTextureCache,
                                                       _pixelBuffer,
                                                       nil,
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA,
                                                       textureSize.width, textureSize.height,
                                                       GL_BGRA,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &_CVGLTexture);
    if (ret != kCVReturnSuccess) {
        NSLog(@"Failed to create OpenGL ES Texture From Image");
        return;
    }
    
    // 3. Get an OpenGL ES texture name from the CVPixelBuffer-backed OpenGL ES texture image.
    self.offscreenTexture = CVOpenGLESTextureGetName(_CVGLTexture);
}

- (void)dealloc{
    NSLog(@"[%@:%p] dealloc", NSStringFromClass(self.class), self);
    if (_pixelBuffer != NULL) {
        CVPixelBufferRelease(_pixelBuffer);
        _pixelBuffer = NULL;
    }
    if (_CVGLTextureCache != NULL) {
        CFRelease(_CVGLTextureCache);
        _CVGLTextureCache = NULL;
    }
    if (_CVGLTexture != NULL) {
        CVBufferRelease(_CVGLTexture);
        _CVGLTexture = NULL;
    }
}

@end
