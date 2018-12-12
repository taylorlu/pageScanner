//
//  ViewController.h
//  pageScanner
//
//  Created by LuDong on 2018/1/15.
//  Copyright © 2018年 LuDong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Endian.h>

#import <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/nonfree/nonfree.hpp>
#include <opencv2/ml/ml.hpp>

#include "generic.h"
#include "mathop.h"
#include "random.h"
#include "gmm.h"
#include "fisher.h"

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate> {
    UIImagePickerController *picker;
    cv::Mat ResImg;
    
    __weak IBOutlet UIImageView *imageView;
    
    AVCaptureVideoDataOutput *output;
    AVCaptureSession     *session;
    AVCaptureDeviceInput *inputDevice;
    AVCaptureVideoPreviewLayer   *previewLayer;
}
- (IBAction)takePhoto:(id)sender;


@end

