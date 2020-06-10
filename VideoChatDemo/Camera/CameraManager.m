//
//  CameraManager.m
//  VideoChatDemo
//
//  Created by menthu on 2020/6/9.
//  Copyright © 2020 menthu. All rights reserved.
//

#import "CameraManager.h"
#import <AVFoundation/AVFoundation.h>

static NSInteger const FRAME_PER_SECOND = 20;

@interface CameraManager () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, assign) BOOL isCameraFront;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (strong, nonatomic) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (weak, nonatomic) AVCaptureDeviceInput *videoDataInput;
@property (weak, nonatomic) AVCaptureVideoDataOutput *sessionVideoOutput;
@property (weak, nonatomic) AVCaptureConnection *outputConnection;

@end

@implementation CameraManager

- (instancetype)init{
    if (self = [super init]) {
        [self initData];
        [self initSession];
    }
    return self;
}

- (void)initData{
   self.isCameraFront = YES;
}

- (void)initSession{
    /*
     *  创建队列
     */
    self.sessionQueue = dispatch_queue_create("menthu.camera.opengl.sessionqueue", DISPATCH_QUEUE_SERIAL);
    
    /*
     *  创建会话
     */
    NSString *sessionPreset = AVCaptureSessionPreset1280x720;
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    if (![session canSetSessionPreset:sessionPreset]) {
        session.sessionPreset = sessionPreset;
    }else{
        session.sessionPreset = AVCaptureSessionPreset640x480;
    }
    self.session = session;
    
    /*
     *  添加摄像头到会话
     */
    AVCaptureDevicePosition cameraPosition = self.isCameraFront ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    AVCaptureDevice *device = [self cameraWithPosition:cameraPosition];
    if (device) {
        AVCaptureDeviceInput *videoDataInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
        if ([session canAddInput:videoDataInput]) {
            [session addInput:videoDataInput];
        }
        self.videoDataInput = videoDataInput;
        self.captureDevice = device;
        /*
         *  设置帧率
         */
        NSError *error = nil;
        [self.captureDevice lockForConfiguration:&error];
        if (error == nil) {
            [self.captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, FRAME_PER_SECOND)];
            [self.captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, FRAME_PER_SECOND)];
        }
        [self.captureDevice unlockForConfiguration];
    }else{
        NSAssert(NO, @"Can't Find Required Camera");
        return;
    }
    
    /*
     *  这里其实指定了采集的像素格式为NV12
     *  BiPlanar表示UV存储在一起
     *  Planar表示UV开存储
     */
    NSMutableDictionary *videoOutputSetting = [NSMutableDictionary dictionary];
    videoOutputSetting[(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey] = @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);
    AVCaptureVideoDataOutput *sessionVideoOutput = [[AVCaptureVideoDataOutput alloc] init];
    sessionVideoOutput.alwaysDiscardsLateVideoFrames = YES;
    [sessionVideoOutput setVideoSettings:videoOutputSetting];
    [sessionVideoOutput setSampleBufferDelegate:self queue:self.sessionQueue];
    if ([session canAddOutput:sessionVideoOutput]) {
        [session addOutput:(_sessionVideoOutput = sessionVideoOutput)];
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
    if (![AVCaptureDeviceInput class]) {
        return;
    }
    if (self.isCameraFront == isFront) {
        return;
    }
    self.isCameraFront = isFront;
    
    
    
    [self.session beginConfiguration];
    {
        AVCaptureDevice *newCamera = [self cameraWithPosition:self.isCameraFront ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
        
        for (AVCaptureInput *input in [self.session inputs]) {
            [self.session removeInput:input];
        }
        if ([self.session canAddInput:newInput]) {
            [self.session addInput:newInput];
        } else {
            NSLog(@"Couldn't add video output");
            [self.session commitConfiguration];
            return;
        }
        self.videoDataInput = newInput;
        
        NSError *error = nil;
        [self.captureDevice lockForConfiguration:&error];
        if (error == nil) {
            [self.captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, FRAME_PER_SECOND)];
            [self.captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, FRAME_PER_SECOND)];
        }
        [self.captureDevice unlockForConfiguration];
    }
    [self.session commitConfiguration];
    
    if ([AVCaptureDeviceInput class]){
        [self.session beginConfiguration];
        
        AVCaptureDevice *newCamera = [self cameraWithPosition:self.isCameraFront ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
        
        for (AVCaptureInput *input in [_session inputs]) {
            [_session removeInput:input];
        }
        if ([_session canAddInput:newInput]) {
            [_session addInput:newInput];
            self.videoDataInput = newInput;
        }
        [_session commitConfiguration];
    }
}

- (id)cameraWithPosition:(AVCaptureDevicePosition)position{
    if ([AVCaptureSession class]){
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices){
            if (device.position == position){
                return device;
                break;
            }
        }
    }
    return nil;
}

#pragma mark - aaa
- (void)captureOutput:(AVCaptureOutput *)output
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
           fromConnection:(AVCaptureConnection *)connection {
    if (self.cameraDelegate && [self.cameraDelegate respondsToSelector:@selector(didCaptureVideoFrame:)]) {

        /*
         *  获取sampleBuffer中的pixel数据且CMSampleBufferGetImageBuffer没有retain返回的数据，如果外层需要持有数据，需要显示调用retain
         */
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

        /*
         *  在sampleBuffer中，找到所有sample显示时间戳中最早的那个并返回
         */
        CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        if (CMTIME_IS_INVALID(currentTime)) {
            NSLog(@"Invalid frame buffer CMTime.");
            return;
        }

        /*
         *  在CPU访问pixel数据时，需要对这块内存上锁
         */
        CVPixelBufferLockBaseAddress(imageBuffer, 0);

        /*
         *  返回CVImageBufferRef的宽度，单位像素
         *  与CVPixelBufferGetBytesPerRowOfPlane不同的是，它返回的是不含padding内容的大小，对真实Y/UV平面计算有帮助
         */
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t heightOfYPlane = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
        size_t heightOfUVPlane = CVPixelBufferGetHeightOfPlane(imageBuffer, 1);
        size_t totalHeight = CVPixelBufferGetHeight(imageBuffer);

        /*
         *  CVPixelBufferGetBaseAddressOfPlane 获取每个平面的指针
         */
        unsigned char *baseAddrYPlane = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        unsigned char *baseAddrUVPlane = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
        unsigned char *totalPixelPlane = (unsigned char *)CVPixelBufferGetBaseAddress(imageBuffer);

        NSLog(@"heightOfYPlane=[%d] heightOfUVPlane=[%d] totalHeight=[%d]", heightOfYPlane, heightOfUVPlane, totalHeight);

        size_t numberPerRowOfYPlane = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
        size_t numberPerRowOfUVPlane = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);

        size_t extraColumnsOnLeft = 0;
        size_t extraColumnsOnRight = 0;
        size_t extraRowsOnTop = 0;
        size_t extraRowsOnBottom = 0;

        CVPixelBufferGetExtendedPixels(imageBuffer, &extraColumnsOnLeft, &extraColumnsOnRight, &extraRowsOnTop, &extraRowsOnBottom);

        /*
         *  剔除YUV中可能存在Padding内容
         */
        size_t nBufferSize = width * (heightOfYPlane + heightOfUVPlane);
        unsigned char *pCamBuffer = (unsigned char *)malloc(nBufferSize);
        if (!pCamBuffer) {
            NSLog(@"new buffer exception:captureOutput ;size:%lu", nBufferSize);
            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
            return;
        }

        unsigned char *pTempBuffer = pCamBuffer;
        if (numberPerRowOfUVPlane == width) {
            memcpy(pCamBuffer, baseAddrYPlane, width * heightOfYPlane);
            memcpy(pCamBuffer + width * heightOfYPlane, baseAddrUVPlane, width * heightOfUVPlane);
        } else {
            for (int i = 0; i < heightOfYPlane; i++) {
                memcpy(pTempBuffer, baseAddrYPlane + extraRowsOnTop * numberPerRowOfYPlane + extraColumnsOnLeft, width);
                /*
                 *  这一步很恶心（因为我也是Copy别人的代码，然后修改一下）
                 *  baseAddrYPlane是从Y平面起始点开始，每复制完一行就下移一行，然后再计算真实内容下一行的偏移量
                 */
                baseAddrYPlane += numberPerRowOfYPlane;
                pTempBuffer += width;
            }
            for (int i = 0; i < heightOfUVPlane; i++) {
                memcpy(pTempBuffer, baseAddrUVPlane + extraRowsOnTop * numberPerRowOfUVPlane + extraColumnsOnLeft, width);
                baseAddrUVPlane += numberPerRowOfUVPlane;
                pTempBuffer += width;
            }
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        
        
        VideoFrame *frame = [VideoFrame new];
        frame.yuvBuffer = pCamBuffer;
        frame.yuvBufferSize = nBufferSize;
        frame.width = width;
        frame.height = heightOfYPlane;
        [self.cameraDelegate didCaptureVideoFrame:frame];
    }
}

@end
