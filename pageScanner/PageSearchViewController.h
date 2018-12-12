//
//  PageSearchViewController.h
//  pageScanner
//
//  Created by LuDong on 2018/2/5.
//  Copyright © 2018年 LuDong. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CommViewController.h"

@interface PageSearchViewController : CommViewController {
    
    float *means;
    float *covariances;
    float *priors;
    cv::Mat weightMat;
    cv::Mat meanVectors;
    std::vector<cv::Mat> wholeImgsDescriptors;
    cv::Mat wholeFVData;
    cv::Mat wholeVladData;
    cv::PCA pca;
    
    float *leafCenters;
    float *idf;
    int *hikmCenters;
    VlHIKMTree *hikmTree;
    int subTrees;
    int depth;
    int nclusters;
    
    __weak IBOutlet UIImageView *pre3ImageView;
    __weak IBOutlet UIImageView *pre2ImageView;
    __weak IBOutlet UIImageView *predImageView;
    __weak IBOutlet UIImageView *capImageView;
    __weak IBOutlet UIButton *takeBtn;
}

- (IBAction)takePhotoAction:(id)sender;

@end
