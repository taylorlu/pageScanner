//
//  PageSearchViewController.m
//  pageScanner
//
//  Created by LuDong on 2018/2/5.
//  Copyright © 2018年 LuDong. All rights reserved.
//

#import "PageSearchViewController.h"
using namespace cv;

@interface PageSearchViewController ()

@end

@implementation PageSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    isCapture = false;
    originData = (uint8_t *)malloc(1280*720);
    
    //gmm model, fv database
    [self readModel:[[[NSBundle mainBundle] pathForResource:@"gmm" ofType:@"h5"] UTF8String] means:&means covariances:&covariances priors:&priors];

    wholeFVData = readMatrix([[[NSBundle mainBundle] pathForResource:@"standardFVs" ofType:@"h5"] UTF8String]);

#ifdef ENABLE_PCA
    loadPCA([[[NSBundle mainBundle] pathForResource:@"pca" ofType:@"h5"] UTF8String], pca);
#endif

    //vlad database
    //3 subTree, 5 depth.
    subTrees = 3;
    depth = 5;
    nclusters = pow(subTrees, depth);
    hikmTree = vl_hikm_new(VL_IKM_LLOYD);
    vl_hikm_init(hikmTree, SIFT_DIMENSION, subTrees, depth);
    
    idf = (float *)readMatrix([[[NSBundle mainBundle] pathForResource:@"idf" ofType:@"h5"] UTF8String], H5T_NATIVE_FLOAT);
    
    hikmCenters = (int *)readMatrix([[[NSBundle mainBundle] pathForResource:@"hikmCenter" ofType:@"h5"] UTF8String], H5T_NATIVE_INT32);
    int count = 0;
    hikmTree->root = initTreeUsingCenters(hikmTree, hikmCenters, count, subTrees, depth);
    
    leafCenters = (float *)malloc(nclusters*SIFT_DIMENSION*sizeof(float));
    count = 0;
    getLeafCenters(hikmTree->root, subTrees, leafCenters, count, depth);
    
    wholeVladData = readMatrix([[[NSBundle mainBundle] pathForResource:@"standardVlads" ofType:@"h5"] UTF8String]);
    
    [self startCapture:capImageView];
}

void sortColVector(Mat vector, int topN, int *index) {//sort col vector only topN, return index of topN
    
    float provit = 0;
    float lastLargeValue = FLT_MAX;
    
    for(int i=0; i<topN; i++) {
        for(int row=0; row<vector.rows; row++) {
            
            float *curData = (float *)(vector.data + row*vector.step[0]);
            if(*curData>provit && *curData<lastLargeValue) {
                index[i] = row;
                provit = *curData;
            }
        }
        lastLargeValue = provit;
        provit = 0;
    }
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
    
    SiftDescriptorExtractor detector;
    vector<KeyPoint> keypoints;
    detector.detect(cloneMat, keypoints);
    Mat descriptors;
    detector.compute(cloneMat, keypoints, descriptors);
    
#ifdef ENABLE_PCA
    Mat fisherVector;
    [self computeFisherVector:descriptors means:means covariances:covariances path:priors fvMat:fisherVector];
    Mat fvReduce = cvCreateMat(1, MAX_DIMENSION, fisherVector.type());
    pca.project(fisherVector, fvReduce);
    transpose(fvReduce, fvReduce);
    Mat ddd = wholeData*fvReduce;
#else
    Mat fisherVector;
    [self computeFisherVector:descriptors means:means covariances:covariances path:priors fvMat:fisherVector];
    transpose(fisherVector, fisherVector);
    Mat fvResult = wholeFVData*fisherVector;
#endif
    
    Mat vladVector = computeVlad(hikmTree, nclusters, subTrees, depth, idf, leafCenters, descriptors);
    transpose(vladVector, vladVector);
    Mat vladResult = wholeVladData*vladVector;
    
    //Fisher vector
    int topN = 5;
    int index[topN];
    int vladTop=0, fvTop=0;
    sortColVector(fvResult, topN, index);
    fvTop = index[0];
    for(int i=0; i<topN; i++) {
        printf("fv %d : %f\n", index[i], *(float *)(fvResult.data + index[i]*fvResult.step[0]));
    }
    //Vlad vector
    printf("\n====\n");
    sortColVector(vladResult, topN, index);
    vladTop = index[0];
    for(int i=0; i<topN; i++) {
        printf("vlad %d : %f\n", index[i], *(float *)(vladResult.data + index[i]*vladResult.step[0]));
    }
    
//    if(*(float *)(ddd.data + index[0]*ddd.step[0])>0.4) {
//        printf("%d : %f\n", index[0], *(float *)(ddd.data + index[0]*ddd.step[0]));
        NSString *labelStr = [NSString stringWithFormat:@"standard%02d", fvTop];
        NSString *imageName = [[NSBundle mainBundle] pathForResource:labelStr ofType:@"jpg"];
        [predImageView setImage:[UIImage imageNamed:imageName]];
    
    labelStr = [NSString stringWithFormat:@"standard%02d", vladTop];
    imageName = [[NSBundle mainBundle] pathForResource:labelStr ofType:@"jpg"];
    [pre2ImageView setImage:[UIImage imageNamed:imageName]];
    
    labelStr = [NSString stringWithFormat:@"standard%02d", index[2]];
    imageName = [[NSBundle mainBundle] pathForResource:labelStr ofType:@"jpg"];
    [pre3ImageView setImage:[UIImage imageNamed:imageName]];
//    }
//    else {
//        [predImageView setImage:nil];
//    }
    printf("\n============\n");

    return 0;
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
        [pre2ImageView setImage:nil];
        [pre3ImageView setImage:nil];
    }
}

@end
