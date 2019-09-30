//
//  VideoManager.m
//  VideoChatDemo
//
//  Created by menthu on 2019/8/25.
//  Copyright © 2019 menthu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoManager.h"
#import "VideoFrame.h"

static NSInteger const VIDEO_FPS = 30;

@interface VideoManager ()<AVCaptureVideoDataOutputSampleBufferDelegate> {
    dispatch_queue_t _sessionQueue;
    unsigned char *_rotateBuffer;
    size_t _rotateBufferSize;
}

@property (strong, nonatomic) AVCaptureSession *session;
@property (weak, nonatomic) AVCaptureVideoDataOutput *sessionVideoOutput;
@property (weak, nonatomic) AVCaptureDeviceInput *videoDataInput;
@property (weak, nonatomic) AVCaptureConnection *outputConnection;
@property (weak, nonatomic) id<VideoDelegate> delegate;
@property (copy, nonatomic) void (^callBack) (CVPixelBufferRef imgeData);
@property (assign, nonatomic) BOOL isFront;
@property (assign, nonatomic) CGFloat currentImgAngle;

@end

@implementation VideoManager

- (instancetype)initWithDelegate:(id<VideoDelegate>)delegate isFront:(BOOL)isFront{
    if (self = [super init]) {
        self.isFront = isFront;
        self.delegate = delegate;
        [self getImgAngleWithDeviceOrientationL:UIDevice.currentDevice.orientation];
        
        [self initVideo];
        [self initNotification];
    }
    return self;
}

- (void)initNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)deviceOrientationDidChange{
    UIDeviceOrientation orientation = UIDevice.currentDevice.orientation;
    dispatch_async(_sessionQueue, ^{
        [self getImgAngleWithDeviceOrientationL:orientation];
    });
}

- (void)initVideo{
    //创建处理会话
    _sessionQueue = dispatch_queue_create("_sessionQueue", DISPATCH_QUEUE_SERIAL);
    
    //创建会话
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPreset1280x720;
    self.session = session;
    
    //添加后置摄像头到会话
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices){
        //AVCaptureDevicePositionBack
        //AVCaptureDevicePositionFront
        if (device.position == (self.isFront ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack)){
            AVCaptureDeviceInput *videoDataInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
            if ([session canAddInput:videoDataInput]) {
                [session addInput:videoDataInput];
            }
            self.videoDataInput = videoDataInput;
        }
    }
    
    //添加输出
    NSMutableDictionary *videoOutputSetting = @{}.mutableCopy;
    videoOutputSetting[(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey] = @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);
    AVCaptureVideoDataOutput *sessionVideoOutput = [[AVCaptureVideoDataOutput alloc] init];
    sessionVideoOutput.alwaysDiscardsLateVideoFrames = YES;
    [sessionVideoOutput setVideoSettings:videoOutputSetting];
    [sessionVideoOutput setSampleBufferDelegate:self queue:_sessionQueue];
    if ([session canAddOutput:sessionVideoOutput]) {
        [session addOutput:(_sessionVideoOutput = sessionVideoOutput)];
    }
    
    
    
    _rotateBufferSize = 0;
    self.outputConnection = [self.sessionVideoOutput connectionWithMediaType:AVMediaTypeVideo];
    //        connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    //        [connection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
    //        AVCaptureConnection *conn = [self.sessionVideoOutput connectionWithMediaType:AVMediaTypeVideo];
    //        if ([conn isVideoMinFrameDurationSupported])
    //            conn.videoMinFrameDuration = CMTimeMake(1,(int32_t)VIDEO_FPS);
    //        if ([conn isVideoMaxFrameDurationSupported])
    //            conn.videoMaxFrameDuration = CMTimeMake(1,(int32_t)VIDEO_FPS);
}

void rotate90NV12(unsigned char *dst, const unsigned char *src, int srcWidth, int srcHeight){
    int wh = srcWidth * srcHeight;
    int uvHeight = srcHeight / 2;
    int uvWidth = srcWidth / 2;
    
    //旋转Y
    int i = 0, j = 0;
    int srcPos = 0, nPos = 0;
    for(i = 0; i < srcHeight; i++) {
        nPos = srcHeight - 1 - i;
        for(j = 0; j < srcWidth; j++) {
            dst[j * srcHeight + nPos] = src[srcPos++];
        }
    }
    
    srcPos = wh;
    for(i = 0; i < uvHeight; i++) {
        nPos = (uvHeight - 1 - i) * 2;
        for(j = 0; j < uvWidth; j++) {
            dst[wh + j * srcHeight + nPos] = src[srcPos++];
            dst[wh + j * srcHeight + nPos + 1] = src[srcPos++];
        }
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if ([self.delegate respondsToSelector:@selector(didCaptureVideoFrame:)]) {
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        //解析NV12数据
        size_t width                    = CVPixelBufferGetWidth(imageBuffer);
        size_t heightOfYPlane           = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
        //        size_t heightOfUVPlane          = CVPixelBufferGetHeightOfPlane(imageBuffer, 1);
        size_t nBufferSize              = width * heightOfYPlane;//width * (heightOfYPlane + heightOfUVPlane);
        
        unsigned char* BaseAddrYPlane   = (unsigned char*) CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        //        unsigned char* BaseAddrUVPlane  = (unsigned char*) CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
        
        size_t numberPerRowOfUVPlane = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,1);
    
        
        
        unsigned char *pCamBuffer = (unsigned char *)malloc(nBufferSize);
        if (NULL == pCamBuffer) {
            NSLog(@"malloc exception:captureOutput ;size:%lu",nBufferSize);
            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
            return;
        }
        
        
        if (numberPerRowOfUVPlane == width) {
            NSInteger countOfY = width*heightOfYPlane;
            memcpy(pCamBuffer, BaseAddrYPlane, countOfY);
            
            //            NSInteger startOfU = width * heightOfYPlane;
            //            NSInteger startOfV = width * heightOfYPlane * 5/4.f;
            //
            //            for (NSInteger index = 0; index < heightOfUVPlane; index ++) {
            //                NSInteger lineStartOffset = index * numberPerRowOfUVPlane;
            //                for (NSInteger x = 0; x < numberPerRowOfUVPlane-1; x+=2) {
            //                    //NV12 -> I420
            //                    NSInteger indexOfU = lineStartOffset + x;
            //                    NSInteger indexOfV = indexOfU + 1;
            //                    pCamBuffer[startOfU++] = BaseAddrUVPlane[indexOfU];
            //                    pCamBuffer[startOfV++] = BaseAddrUVPlane[indexOfV];
            //                }
            //            }
        }else{
            //            size_t extraColumnsOnLeft       = 0;
            //            size_t extraColumnsOnRight      = 0;
            //            size_t extraRowsOnTop           = 0;
            //            size_t extraRowsOnBottom        = 0;
            //            CVPixelBufferGetExtendedPixels(imageBuffer, &extraColumnsOnLeft, &extraColumnsOnRight, &extraRowsOnTop, &extraRowsOnBottom);
            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
            free(pCamBuffer);
            NSAssert(NO, @"NV12数据不对齐");
            return;
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        
        VideoFrame *frame = VideoFrame.new;
        frame->_imgData = pCamBuffer;
        frame.imgType = YUVTYpe_I420;
        frame.imgWidth = (int)width;
        frame.imgHeight = (int)heightOfYPlane;
        frame.imgAngle = self.currentImgAngle;
        frame.needMirror = self.isFront;
        
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.delegate didCaptureVideoFrame:frame];
            free(frame->_imgData);
            frame->_imgData = NULL;
        });
    }
}

- (void)getImgAngleWithDeviceOrientationL:(UIDeviceOrientation)deviceOrientation{
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait://homeBottom
        {
            self.currentImgAngle = M_PI_2;
        }
            break;
        case UIDeviceOrientationPortraitUpsideDown://homeTop
        {
            //do nothing
            //跟随上一个状态
        }
            break;
        case UIDeviceOrientationLandscapeLeft://homeRight
        {
            self.currentImgAngle = self.isFront ? M_PI : 0;
        }
            break;
            
        case UIDeviceOrientationLandscapeRight://homeLeft
        {
            self.currentImgAngle = self.isFront ? 0 : M_PI;
        }
            break;
            
        default:
            break;
    }
}

- (void)startCapture{
    if (![self.session isRunning]) {
        [self.session startRunning];
    }
}

- (void)stopCapture{
    if ([self.session isRunning]) {
        [self.session stopRunning];
    }
}

- (void)switchCameraPosition:(BOOL)isFront{
    if (self.isFront == isFront) {
        return;
    }
    dispatch_sync(_sessionQueue, ^{
        self.isFront = isFront;
    });
    if ([AVCaptureDeviceInput class]){
        [_session beginConfiguration];
        
        AVCaptureDevice *newCamera = nil;
        AVCaptureDeviceInput *newInput = nil;
        if (isFront) {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
        }else{
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }
        newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
        
        for (AVCaptureInput *input in [_session inputs]) {
            [_session removeInput:input];
        }
        if ([_session canAddInput:newInput]) {
            [_session addInput:newInput];
            self.videoDataInput = newInput;
        }
        
//        AVCaptureConnection *conn = [self.sessionVideoOutput connectionWithMediaType:AVMediaTypeVideo];
//        if ([conn isVideoMinFrameDurationSupported]){
//            conn.videoMinFrameDuration = CMTimeMake(1,(int32_t)_frameRate);
//        }
//        if ([conn isVideoMaxFrameDurationSupported]){
//            conn.videoMaxFrameDuration = CMTimeMake(1,(int32_t)_frameRate);
//        }
        
        [_session commitConfiguration];
    }
}

- (id)cameraWithPosition:(AVCaptureDevicePosition)position{
    if ([AVCaptureSession class]){
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices){
            if (device.position == position){
                return device;
            }
        }
    }
    return nil;
}

- (void)getOneFrame:(void (^) (CVPixelBufferRef imgeData))callBack{
    self.callBack = callBack;
}

@end
