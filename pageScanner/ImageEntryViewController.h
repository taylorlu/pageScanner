//
//  ImageEntryViewController.h
//  pageScanner
//
//  Created by LuDong on 2018/2/26.
//  Copyright © 2018年 LuDong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommViewController.h"
#import "yuvrgb.h"

@interface ImageEntryViewController : CommViewController {
    
    float *means;
    float *covariances;
    float *priors;
    
    __weak IBOutlet UIImageView *pdImageView;
    __weak IBOutlet UIButton *takePhotoBtn;
    __weak IBOutlet UIButton *enterBtn;
    __weak IBOutlet UIButton *retrieveBtn;
    __weak IBOutlet UIImageView *imageView;
//    UIAlertController *alert;
    
    cv::Mat descriptors;
    cv::Mat fisherVector;
    NSData *ptData;
    int ptCount;
}
- (IBAction)takePhoneAction:(id)sender;

- (IBAction)uploadAction:(id)sender;

- (IBAction)retrieveAction:(id)sender;
@end
