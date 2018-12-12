//
//  PageScanViewController.m
//  pageScanner
//
//  Created by LuDong on 2018/1/23.
//  Copyright © 2018年 LuDong. All rights reserved.
//

#import "PageScanViewController.h"

using namespace cv;

@interface PageScanViewController ()

@end

@implementation PageScanViewController

//float calcVectorCosAngle(Mat rowVector, Mat colVector) {
//
//    Mat dotMat = rowVector*colVector;
//    float *dot = (float *)dotMat.data;
//
//    float mol1 = norm(rowVector, CV_L2);
//    float mol2 = norm(colVector, CV_L2);
////    printf("\n=====mol1=%f, mol2=%f\n", mol1, mol2);
//    return (*dot)/(mol1*mol2);
//}
//
//Mat getClassMeanVectors(const char *path) {
//
//    hid_t fileId = H5Fopen(path, H5F_ACC_RDONLY, H5P_DEFAULT);
//
//    ////get dataset 1
//    hid_t datasetId = H5Dopen1(fileId, "fileName");
//    hid_t spaceId = H5Dget_space(datasetId);
//    int ndims = H5Sget_simple_extent_ndims(spaceId);
//    hsize_t dims[ndims];
//    herr_t status = H5Sget_simple_extent_dims(spaceId, dims, NULL);
//
//    int rows = (int)dims[0];
//    int cols = (int)dims[1];
//    int cap = rows*cols;
//    float *weights = (float *)malloc(sizeof(float)*cap);
//    hid_t memspace = H5Screate_simple(ndims, dims, NULL);
//    status = H5Dread(datasetId, H5T_NATIVE_FLOAT, memspace, spaceId, H5P_DEFAULT, weights);
//
//    Mat meanMat(rows, cols, CV_32F, weights);
//
//    status = H5Sclose(spaceId);
//    status = H5Dclose(datasetId);
//    H5Fclose(fileId);
//    return meanMat;
//}
//
//-(void)calcWholeImgsDescriptor {
//
//    for(int i=0; i<19; i++) {
//        NSString *labelStr = [NSString stringWithFormat:@"label%02d", i];
//        NSString *imageName = [[NSBundle mainBundle] pathForResource:labelStr ofType:@"jpg"];
//
//        Mat imgMat2(cvLoadImage([imageName UTF8String]));
//        cvtColor(imgMat2, imgMat2, CV_BGR2GRAY);
//        imgMat2 = imgMat2.clone();
//
//        SiftDescriptorExtractor detector2;
//        vector<KeyPoint> keypoints2;
//        detector2.detect(imgMat2, keypoints2);
//        Mat descriptors2;
//        detector2.compute(imgMat2, keypoints2, descriptors2);
//
//        wholeImgsDescriptors.push_back(descriptors2);
//    }
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    isCapture = false;
    originData = (uint8_t *)malloc(1280*720);
    
    [self readModel:[[[NSBundle mainBundle] pathForResource:@"gmm20_sp10" ofType:@"h5"] UTF8String] means:&means covariances:&covariances priors:&priors];
    
    weightMat = [self softmaxW:19 path:[[[NSBundle mainBundle] pathForResource:@"softmax10" ofType:@"pkl"] UTF8String]];

//    meanVectors = getClassMeanVectors([[[NSBundle mainBundle] pathForResource:@"classVector" ofType:@"hdf5"] UTF8String]);
//    transpose(meanVectors, meanVectors);

//    [self calcWholeImgsDescriptor];
    
    [self startCapture:capImageView];
    // Do any additional setup after loading the view.
}

void saveFile(uint8_t *data, int len, const char *filename) {
    NSArray *arrDocumentPaths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *documentPath=[arrDocumentPaths objectAtIndex:0];
    NSString *filePath = [documentPath stringByAppendingString:[NSString stringWithUTF8String:filename]];
    FILE *file = fopen([filePath UTF8String], "wb");
    fwrite(data, len, 1, file);
    fclose(file);
}

-(int)predictGray {

    Mat imgMat;
    imgMat.create(720, 1280, CV_8U);
    memcpy(imgMat.data, originData, 1280*720);

    cv::Size ResImgSiz = cv::Size(840, 640);
    resize(imgMat, imgMat, ResImgSiz, CV_INTER_LINEAR);

    transpose(imgMat, imgMat);
    flip(imgMat, imgMat, 1);
    Mat cloneMat = imgMat.clone();
    
    SiftDescriptorExtractor detector(SIFT_COUNT);
    vector<KeyPoint> keypoints;
    detector.detect(cloneMat, keypoints);
    Mat descriptors;
    detector.compute(cloneMat, keypoints, descriptors);
    
    Mat fisherVector;
    [self computeFisherVector:descriptors means:means covariances:covariances path:priors fvMat:fisherVector];

    Mat result = fisherVector*weightMat;
    
    float *data = (float *)result.data;
    float privot = data[0];
    int index = 0;
    for(int i=1;i<result.cols;i++) {
        float *curData = (float *)(result.data + i*result.step[1]);
//        printf("[%d] curData = %f\n", i, *curData);
        
        if(*curData>privot) {
            privot = *curData;
            index = i;
        }
//        Mat colVector = meanVectors.col(i);
//        float angle = calcVectorCosAngle(fisherVector, colVector);
//        printf("                 angle = %f\n", angle);
    }
    
    NSString *labelStr = [NSString stringWithFormat:@"label%02d", index];
    NSString *imageName = [[NSBundle mainBundle] pathForResource:labelStr ofType:@"jpg"];
    [predImageView setImage:[UIImage imageNamed:imageName]];
    printf("index = %d, data = %f\n", index, privot);
    
    ////////////////
    
//    DescriptorMatcher *pMatcher = new FlannBasedMatcher;
//    vector<DMatch> matches;
//    pMatcher->match(descriptors, wholeImgsDescriptors[index], matches);
//    printf("%d,,,,,,,,%d\n", descriptors.rows, wholeImgsDescriptors[index].rows);
//    sort(matches.begin(), matches.end());
//
//    int count100Index = 0;
//    for(int i=0; i<matches.size(); i++) {
//        if(matches[i].distance>100)
//            break;
//        count100Index++;
//    }
//    printf("match count = %d\n", count100Index);
//    printf("probability = %f\n", (float)count100Index/(float)descriptors.rows);
    ////////////////
    
    return index;
}

- (IBAction)takePhotoAction:(id)sender {
    
    if(isCapture) {
        [session stopRunning];
        [takeBtn setTitle:@"start capture" forState:UIControlStateNormal];
        isCapture = false;
        
        [self predictGray];
    }
    else {
        [session startRunning];
        [takeBtn setTitle:@"take photo" forState:UIControlStateNormal];
        isCapture = true;
        [predImageView setImage:nil];
//        [predImageView setBackgroundColor:[UIColor grayColor]];
    }
}
@end
