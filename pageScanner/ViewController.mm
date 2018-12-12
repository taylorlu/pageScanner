//
//  ViewController.m
//  pageScanner
//
//  Created by LuDong on 2018/1/15.
//  Copyright © 2018年 LuDong. All rights reserved.
//

#import "ViewController.h"

using namespace cv;

@interface ViewController ()

@end

@implementation ViewController

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection  {
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    CVPlanarPixelBufferInfo_YCbCrBiPlanar *bufferInfo = (CVPlanarPixelBufferInfo_YCbCrBiPlanar *)baseAddress;
    
    NSUInteger yOffset = EndianU32_BtoN(bufferInfo->componentInfoY.offset);
    uint8_t *y = baseAddress + yOffset;
    
    printf("capture..\n");

//    memcpy(originalData, y, 1280*720);
}

-(void)startCapture {

    NSArray *cameraArray = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in cameraArray) {
        if ([device position] == AVCaptureDevicePositionBack) {
            inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
        }
    }
    
    session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPreset1280x720;
    [session addInput:inputDevice];     //输入设备与session连接
    
    /*  设置输出yuv格式   */
    output = [[AVCaptureVideoDataOutput alloc] init];
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:value forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    [output setVideoSettings:dictionary];
    [output setAlwaysDiscardsLateVideoFrames:YES];
    
    /*  设置本地预览窗口    */
    previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    [previewLayer setMasksToBounds:YES];
    [previewLayer setBorderWidth:2.0];
    [previewLayer setBorderColor:[[UIColor whiteColor] CGColor]];
    [previewLayer setFrame:[imageView frame]];
    
    [[self.view layer] addSublayer:previewLayer];
    
    /*  设置输出回调队列    */
    dispatch_queue_t queue = dispatch_queue_create("com.linku.queue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    //    dispatch_release(queue);
    [session addOutput:output];     //输出与session连接
    
    [session startRunning];
}

-(void)process {

    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"tt14" ofType:@"jpg"];
    UIImage *image = [UIImage imageNamed:imagePath];
    [imageView setImage:image];
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    cv::Mat srcImg(rows, cols, CV_8UC4);
    CGContextRef contextRef = CGBitmapContextCreate(srcImg.data,
                                                    cols,
                                                    rows,
                                                    8,
                                                    srcImg.step[0],
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    cv::Size ResImgSiz = cv::Size(640, 840);
    cv::resize(srcImg, ResImg, ResImgSiz, CV_INTER_LINEAR);
    cv::cvtColor(ResImg, ResImg, COLOR_BGR2GRAY);
    CGContextRelease(contextRef);
    
    SiftDescriptorExtractor detector;
    vector<KeyPoint> keypoints;
    detector.detect(ResImg, keypoints);
    Mat descriptors;
    detector.compute(ResImg, keypoints, descriptors);

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self startCapture];
    
//    [self process];
//
//    cv::Size ResImgSiz = cv::Size(640, 840);
//    ResImg = cv::Mat(ResImgSiz, CV_8UC1);

}



- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"callback");
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        
        //////////
//        UIImage *testImage = [self fixOrientation:image];
//        CGFloat cols = testImage.size.width;
//        CGFloat rows = testImage.size.height;

        //////////
        CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
        CGFloat cols = image.size.width;
        CGFloat rows = image.size.height;

        cv::Mat srcImg(rows, cols, CV_8UC4);

        CGContextRef contextRef = CGBitmapContextCreate(srcImg.data,
                                                        cols,
                                                        rows,
                                                        8,
                                                        srcImg.step[0],
                                                        colorSpace,
                                                        kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);

        CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
        
//        if(rows>cols) {
//            cv::Size ResImgSiz = cv::Size(640, 840);
//            cv::resize(srcImg, ResImg, ResImgSiz, CV_INTER_LINEAR);
//        }
//        else {
//            cv::Size ResImgSiz = cv::Size(840, 640);
//            cv::resize(srcImg, ResImg, ResImgSiz, CV_INTER_LINEAR);
//            cv::rotate(ResImg, ResImg, cv::ROTATE_90_CLOCKWISE);
//        }
        cv::Size ResImgSiz = cv::Size(640, 840);
        cv::resize(srcImg, ResImg, ResImgSiz, CV_INTER_LINEAR);
//        cv::rotate(ResImg, ResImg, cv::ROTATE_90_CLOCKWISE);

        cv::cvtColor(ResImg, ResImg, COLOR_BGR2GRAY);

        CGContextRelease(contextRef);
    }
    [imageView setImage:[self UIImageFromCVMat:ResImg]];
    [picker dismissViewControllerAnimated:YES completion:nil];
//    [picker dismissViewControllerAnimated:YES completion:^{
//        UIImage *image2 = [self UIImageFromCVMat:ResImg];
//        [[ViewController self] performSelectorOnMainThread:@selector(showImage:) withObject:image2 waitUntilDone:NO];
//    }];
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat {

    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );

    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

- (BOOL)checkCamera
{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(AVAuthorizationStatusRestricted == authStatus ||
       AVAuthorizationStatusDenied == authStatus)
    {
        //相机不可用
        return NO;
    }
    //相机可用
    return YES;
}

- (IBAction)takePhoto:(id)sender {
    
    [session stopRunning];

    
//    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
//        picker = [[UIImagePickerController alloc] init];
//        [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
//        [picker setDelegate:self];
//        BOOL test = [self checkCamera];
//        if(test){
//            NSLog(@"test");
//        }
//        else {
//            NSLog(@"no");
//        }
//        [self presentViewController:picker animated:YES completion:nil];
//    }
//    else {
//        NSLog(@"forbid");
//    }
}
@end
