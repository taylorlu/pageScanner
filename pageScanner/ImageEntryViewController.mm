//
//  ImageEntryViewController.m
//  pageScanner
//
//  Created by LuDong on 2018/2/26.
//  Copyright © 2018年 LuDong. All rights reserved.
//

#import "ImageEntryViewController.h"

using namespace cv;
using namespace std;

@interface ImageEntryViewController ()

@end

@implementation ImageEntryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [pdImageView setBackgroundColor:[UIColor clearColor]];
    [enterBtn setEnabled:NO];
    [retrieveBtn setEnabled:NO];
    
    originData = (uint8_t *)malloc(1280*720*3/2);
    
    //gmm model, fv database
    [self readModel:[[[NSBundle mainBundle] pathForResource:@"gmm" ofType:@"h5"] UTF8String] means:&means covariances:&covariances priors:&priors];
    
    [self startCapture:imageView];
}

-(void)postData:(NSURL *)url withParam:(NSDictionary *)params withData:(NSDictionary *)dataDict {
    
    //Common settings
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
    NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BoundaryConstant];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval:20];
    
    NSMutableData *body = [NSMutableData data];
    
    for(id key in params) {
        //Add W*H parameter
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[params objectForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }

    for(id key in dataDict) {
        
        //Add Fisher Vector
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[dataDict objectForKey:key]];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    //End Boundary
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //Setting the body of the post to the reqeust
    [request setHTTPBody:body];
    
    //Set the Content-Length
    NSString *postLength = [NSString stringWithFormat:@"%lu", [body length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    NSURLSession *sess = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *uploadtask = [sess dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSLog(@"%@", [url path]);
        if([[url path] containsString:@"retrieve"]) {
            [self dealRetriveResponse:httpResponse withData:data];
        }
        else {
            [self dealEntryResponse:httpResponse withData:data];
        }
    }];
    [uploadtask resume];
}

-(void)dealEntryResponse:(NSHTTPURLResponse *)httpResponse withData:(NSData *)data {

    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert;
        if(httpResponse.statusCode==200) {
            alert= [UIAlertController alertControllerWithTitle:@"OK" message:@"图片录入成功" preferredStyle:UIAlertControllerStyleAlert];
        }
        else {
            alert = [UIAlertController alertControllerWithTitle:@"Sorry" message:@"图片录入失败" preferredStyle:UIAlertControllerStyleAlert];
        }
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

-(void)dealRetriveResponse:(NSHTTPURLResponse *)httpResponse withData:(NSData *)data {
    
    if(httpResponse.statusCode==200) {
        UIImage *image = [UIImage imageWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            [pdImageView setImage:image];
        });
    }
    else if(httpResponse.statusCode==400) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sorry" message:@"没找到相似图片" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:cancelAction];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
}

//-(void)commitImage {
//
//    NSString *text = [alert.textFields[0] text];
//    NSLog(@"test = %@", text);
//
//    //Common settings
//    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://10.102.20.24:9000/test"]];
//    NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
//    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BoundaryConstant];
//    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
//    [request setHTTPMethod:@"POST"];
//    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
//    [request setTimeoutInterval:20];
//
//    //Size of NSData
//    long size = descriptors.dataend-descriptors.datastart;
//    NSData *siftMat = [NSData dataWithBytes:descriptors.data length:size];
//    size = fisherVector.dataend-fisherVector.datastart;
//    NSData *fVector = [NSData dataWithBytes:fisherVector.data length:size];
//
//    //Set fileId parameter
//    NSMutableData *body = [NSMutableData data];
//    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"fileId\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[[NSString stringWithFormat:@"%@\r\n", text] dataUsingEncoding:NSUTF8StringEncoding]];
//
//    //Add W*H parameter
//    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"shape\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[[NSString stringWithFormat:@"%d,%d,%d,%d,2,%d\r\n", descriptors.rows, descriptors.cols, fisherVector.rows, fisherVector.cols, ptCount] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//
//    //Add Sift Mat
//    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"siftMat\"; filename=\"\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:siftMat];
//    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//
//    //Add Fisher Vector
//    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"fVector\"; filename=\"\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:fVector];
//    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//
//    //Add SIFT PointXY
//    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"Keypoint\"; filename=\"\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:ptData];
//    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//
//    //End Boundary
//    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
//
//    //Setting the body of the post to the reqeust
//    [request setHTTPBody:body];
//
//    //Set the Content-Length
//    NSString *postLength = [NSString stringWithFormat:@"%lu", [body length]];
//    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
//
//    NSURLSession *sess = [NSURLSession sharedSession];
//
//    NSURLSessionDataTask *uploadtask = [sess dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
//
//        if(httpResponse.statusCode==200&&error==nil) {
//            UIImage *image = [UIImage imageWithData:data];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [pdImageView setImage:image];
//            });
//        }
//        else if(httpResponse.statusCode==400) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sorry" message:@"没找到相似图片" preferredStyle:UIAlertControllerStyleAlert];
//                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
//                [alert addAction:cancelAction];
//                [self presentViewController:alert animated:YES completion:nil];
//            });
//        }
//    }];
//    [uploadtask resume];
//
//    [session startRunning];
//    [enterBtn setTitle:@"录入" forState:UIControlStateNormal];
//    isCapture = true;
//}

-(void)computeFeature {
    
    Mat imgMat;
    imgMat.create(720, 1280, CV_8U);
    memcpy(imgMat.data, originData, 1280*720);
    
    cv::Size ResImgSiz = cv::Size(840, 640);
    resize(imgMat, imgMat, ResImgSiz, CV_INTER_LINEAR);
    
    transpose(imgMat, imgMat);
    flip(imgMat, imgMat, 1);
    Mat cloneMat = imgMat.clone();
    
    SiftDescriptorExtractor detector;
    vector<KeyPoint> keypoints;
    detector.detect(cloneMat, keypoints);
    detector.compute(cloneMat, keypoints, descriptors);
    
    ptCount = (int)keypoints.size();
    float *pointXY = (float *)malloc(ptCount*sizeof(float)*2);
    for(int i=0; i<keypoints.size(); i++) {
        pointXY[i] = keypoints[i].pt.x;
        pointXY[i+ptCount] = keypoints[i].pt.y;
    }
    ptData = [NSData dataWithBytes:pointXY length:ptCount*sizeof(float)*2];
    [self computeFisherVector:descriptors means:means covariances:covariances path:priors fvMat:fisherVector];
}

- (IBAction)takePhoneAction:(id)sender {
    
    if(isCapture) {
        [session stopRunning];
        [takePhotoBtn setTitle:@"重新捕获" forState:UIControlStateNormal];
        isCapture = false;
        
        [enterBtn setEnabled:YES];
        [retrieveBtn setEnabled:YES];
    }
    else {
        [session startRunning];
        [takePhotoBtn setTitle:@"拍照" forState:UIControlStateNormal];
        isCapture = true;
        
        [enterBtn setEnabled:NO];
        [retrieveBtn setEnabled:NO];
        
        [pdImageView setImage:nil];
        [pdImageView setBackgroundColor:[UIColor clearColor]];
    }
}

- (IBAction)uploadAction:(id)sender {
    
    //PNG from yuv data
    Mat yMat;
    yMat.create(720, 1280, CV_8U);
    memcpy(yMat.data, originData, 1280*720);
    
    Mat uMat;
    uMat.create(720/2, 1280/2, CV_8U);
    memcpy(uMat.data, originData+1280*720, 1280*720/4);
    
    Mat vMat;
    vMat.create(720/2, 1280/2, CV_8U);
    memcpy(vMat.data, originData+1280*720*5/4, 1280*720/4);
    
    resize(yMat, yMat, cv::Size(840, 640), CV_INTER_LINEAR);
    transpose(yMat, yMat);
    flip(yMat, yMat, 1);

    resize(uMat, uMat, cv::Size(840/2, 640/2), CV_INTER_LINEAR);
    transpose(uMat, uMat);
    flip(uMat, uMat, 1);

    resize(vMat, vMat, cv::Size(840/2, 640/2), CV_INTER_LINEAR);
    transpose(vMat, vMat);
    flip(vMat, vMat, 1);

    Mat yCloneMat = yMat.clone();
    Mat uCloneMat = uMat.clone();
    Mat vCloneMat = vMat.clone();

    int *rgbData = (int *)malloc(840*640*4);
    uint8_t rotateData[840*640*3/2];
    memcpy(rotateData, yMat.data, 840*640);
    memcpy(rotateData+840*640, uMat.data, 840*640/4);
    memcpy(rotateData+840*640*5/4, vMat.data, 840*640/4);

    YUV420toRGB(rotateData, rgbData, 640, 840);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbData, 840*640*4, NULL);
    CGImageRef imageRef = CGImageCreate(640, 840, 8, 32, 640*4, colorSpace, kCGImageAlphaNoneSkipFirst|kCGBitmapByteOrder32Little, dataProvider, NULL, true, kCGRenderingIntentDefault);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    NSData *pngData = UIImagePNGRepresentation(image);
    free(rgbData);

    CGImageRelease(imageRef);
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(colorSpace);
    
    [self computeFeature];

    NSString *shapeStr = [NSString stringWithFormat:@"%d,%d,%d,%d,2,%d\r\n", descriptors.rows, descriptors.cols, fisherVector.rows, fisherVector.cols, ptCount];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:shapeStr, @"shape", nil];
    
    //Size of NSData
    long size = descriptors.dataend-descriptors.datastart;
    NSData *siftMat = [NSData dataWithBytes:descriptors.data length:size];
    size = fisherVector.dataend-fisherVector.datastart;
    NSData *fVector = [NSData dataWithBytes:fisherVector.data length:size];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:siftMat, @"siftMat", fVector, @"fVector", ptData, @"Keypoint", pngData, @"pngData", nil];

    NSURL *url = [NSURL URLWithString:@"http://10.102.20.24:9000/entry"];
    [self postData:url withParam:params withData:dataDict];
}

- (IBAction)retrieveAction:(id)sender {

    [pdImageView setImage:nil];
    [pdImageView setBackgroundColor:[UIColor clearColor]];
    
    [self computeFeature];
    
    NSString *shapeStr = [NSString stringWithFormat:@"%d,%d,%d,%d,2,%d\r\n", descriptors.rows, descriptors.cols, fisherVector.rows, fisherVector.cols, ptCount];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:shapeStr, @"shape", nil];
    
    //Size of NSData
    long size = descriptors.dataend-descriptors.datastart;
    NSData *siftMat = [NSData dataWithBytes:descriptors.data length:size];
    size = fisherVector.dataend-fisherVector.datastart;
    NSData *fVector = [NSData dataWithBytes:fisherVector.data length:size];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:siftMat, @"siftMat", fVector, @"fVector", ptData, @"Keypoint", nil];
    
    NSURL *url = [NSURL URLWithString:@"http://10.102.20.24:9000/retrieve"];
    [self postData:url withParam:params withData:dataDict];
}

@end
