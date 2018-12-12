//
//  CommViewController.h
//  pageScanner
//
//  Created by LuDong on 2018/2/5.
//  Copyright © 2018年 LuDong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Endian.h>
#import <math.h>

#import <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/nonfree/nonfree.hpp>
#include <opencv2/ml/ml.hpp>

#include "hdf5.h"
#include "generic.h"
#include "mathop.h"
#include "random.h"
#include "gmm.h"
#include "fisher.h"

#include "vlad.h"
#include "hikmeans.h"
#include "ikmeans.h"

#define GM_COUNT    40
#define SIFT_DIMENSION  128
#define FV_DIMENSION 2*GM_COUNT*128
#define MAX_DIMENSION   44

#define SIFT_COUNT  2000

#undef ENABLE_PCA

@interface CommViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    bool isCapture;
    uint8_t *originData;
    
    AVCaptureVideoDataOutput *output;
    AVCaptureSession     *session;
    AVCaptureDeviceInput *inputDevice;
    AVCaptureVideoPreviewLayer   *previewLayer;
    UIImage *previewImage;
}

-(void)startCapture:(UIImageView *)capImageView;

-(void) readModel:(const char *)filename means:(float **)means covariances:(float **)covariances priors:(float **)priors;

void saveMatrix(float *matrix, int rows, int cols, const char *fileName);

cv::Mat readMatrix(const char *fileName);

void *readMatrix(const char *fileName, hid_t dataType);

-(void) computeFisherVector:(cv::Mat)descriptors means:(float *)means covariances:(float *)covariances path:(float *)priors fvMat:(cv::Mat &)fisherVector;

-(cv::Mat) softmaxW: (int)labelCount path:(const char *)path;

void savePCA(const std::string &file_name,cv::PCA pca_);

void loadPCA(const std::string &file_name,cv::PCA &pca_);

//init hikmTree using center data saved in HDF5
VlHIKMNode *initTreeUsingCenters (VlHIKMTree *tree, vl_int32 *data, int &count, vl_size subTrees, vl_size height);

//get the leaf node of kd-tree, and store to leafCenters, by index, vl_int32-->float, due to vlad
void getLeafCenters(VlHIKMNode *node, int &subTrees, float *leafCenters, int &count, vl_size height);

//root node has 3 centers, the penultimate layer node also has 3 centers, traverse only reach penultimate layer
//the center(uint_8) (e.g.:122) but to calculate mean, so change to uint32 in function vl_ikm_get_centers(e.g.:122,0,0,0)
void traverseTree(VlHIKMNode *node, int &subTrees, int *hikmCenters, int &count);

cv::Mat computeVlad(VlHIKMTree *hikmTree, int nclusters, int subTrees, int depth, float *idf, float *leafCenters, cv::Mat descriptors);

@end
