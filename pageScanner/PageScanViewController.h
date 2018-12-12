//
//  PageScanViewController.h
//  pageScanner
//
//  Created by LuDong on 2018/1/23.
//  Copyright © 2018年 LuDong. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CommViewController.h"

@interface PageScanViewController : CommViewController {
    
    float *means;
    float *covariances;
    float *priors;
    cv::Mat weightMat;
    cv::Mat meanVectors;
    std::vector<cv::Mat> wholeImgsDescriptors;
    
    __weak IBOutlet UIImageView *predImageView;
    __weak IBOutlet UIImageView *capImageView;
    __weak IBOutlet UIButton *takeBtn;
}
- (IBAction)takePhotoAction:(id)sender;

@end
