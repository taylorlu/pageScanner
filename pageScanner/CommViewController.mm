//
//  CommViewController.m
//  pageScanner
//
//  Created by LuDong on 2018/2/5.
//  Copyright © 2018年 LuDong. All rights reserved.
//

#import "CommViewController.h"

using namespace cv;

@interface CommViewController ()

@end

@implementation CommViewController

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection  {
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    CVPlanarPixelBufferInfo_YCbCrBiPlanar *bufferInfo = (CVPlanarPixelBufferInfo_YCbCrBiPlanar *)baseAddress;
    
    NSUInteger yOffset = EndianU32_BtoN(bufferInfo->componentInfoY.offset);
    NSUInteger cbCrOffset = EndianU32_BtoN(bufferInfo->componentInfoCbCr.offset);
    uint8_t *y = baseAddress + yOffset;
    uint8_t *c = baseAddress + cbCrOffset;
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t ySize = width*height;
    memcpy(originData, y, ySize*3/2);
    
    int count=0;
    for(int i=0; i<ySize/2; i+=2,count++) {
        originData[ySize+count] = c[i];
    }
    for(int i=1; i<ySize/2; i+=2,count++) {
        originData[ySize+count] = c[i];
    }
//    //save UIImage
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB()();
//    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
//
//    CGContextDrawImage(newContext, CGRectMake(0, 0, 640, 840), newImage);
//    CGImageRef ref = CGBitmapContextCreateImage(newContext);
//    previewImage = [UIImage imageWithCGImage: ref];
//
//    CGContextRelease(newContext);
//    CGColorSpaceRelease(colorSpace);
//    CGImageRelease(newImage);
//    CGImageRelease(ref);

    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

-(void)startCapture:(UIImageView *)capImageView {
    
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
    [previewLayer setBorderColor:[[UIColor clearColor] CGColor]];
    
    [previewLayer setFrame:[capImageView frame]];
    [[self.view layer] addSublayer:previewLayer];
    
    /*  设置输出回调队列    */
    dispatch_queue_t queue = dispatch_queue_create("com.linku.queue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    //    dispatch_release(queue);
    [session addOutput:output];     //输出与session连接
    
    [session startRunning];
    isCapture = true;
}

-(void) readModel:(const char *)filename means:(float **)means covariances:(float **)covariances priors:(float **)priors {

    hid_t fileId = H5Fopen(filename, H5F_ACC_RDONLY, H5P_DEFAULT);
    
    ////get dataset 1
    hid_t datasetId = H5Dopen1(fileId, "/means");
    hid_t spaceId = H5Dget_space(datasetId);
    int ndims = H5Sget_simple_extent_ndims(spaceId);
    hsize_t dims[ndims];
    herr_t status = H5Sget_simple_extent_dims(spaceId, dims, NULL);
    
    int cap = 1;
    for(int i=0; i<ndims; i++) {
        cap *= dims[i];
    }
    *means = (float *)malloc(sizeof(float)*cap);
    hid_t memspace = H5Screate_simple(ndims,dims,NULL);
    status = H5Dread(datasetId, H5T_NATIVE_FLOAT, memspace, spaceId, H5P_DEFAULT, *means);
    
    status = H5Sclose(spaceId);
    status = H5Dclose(datasetId);
    
    ////get dataset 2
    datasetId = H5Dopen1(fileId, "/covs");
    spaceId = H5Dget_space(datasetId);
    ndims = H5Sget_simple_extent_ndims(spaceId);
    hsize_t dims2[ndims];
    status = H5Sget_simple_extent_dims(spaceId, dims2, NULL);
    
    cap = 1;
    for (int i=0; i<ndims; i++) {
        cap *= dims2[i];
    }
    *covariances = (float *)malloc(sizeof(float)*cap);
    memspace = H5Screate_simple(ndims,dims2,NULL);
    status = H5Dread(datasetId, H5T_NATIVE_FLOAT, memspace, spaceId, H5P_DEFAULT, *covariances);
    
    H5Sclose(spaceId);
    H5Dclose(datasetId);
    
    ////get dataset 3
    datasetId = H5Dopen1(fileId, "/priors");
    spaceId = H5Dget_space(datasetId);
    ndims = H5Sget_simple_extent_ndims(spaceId);
    hsize_t dims3[ndims];
    status = H5Sget_simple_extent_dims(spaceId, dims3, NULL);
    
    cap = 1;
    for (int i=0; i<ndims; i++) {
        cap *= dims3[i];
    }
    *priors = (float *)malloc(sizeof(float)*cap);
    memspace = H5Screate_simple(ndims,dims3,NULL);
    status = H5Dread(datasetId, H5T_NATIVE_FLOAT, memspace, spaceId, H5P_DEFAULT, *priors);
    
    H5Sclose(spaceId);
    H5Dclose(datasetId);
    H5Fclose(fileId);
}

void saveMatrix(float *matrix, int rows, int cols, const char *fileName) {
    
    //save fisher vectors(images, so a matrix) in each class folder, (label-00, label-01, ...)
    hid_t fileId = H5Fcreate(fileName, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);
    
    hsize_t dims[] = {(hsize_t)rows, (hsize_t)cols};
    hid_t dataSpaceId = H5Screate_simple(2, dims, NULL);
    hid_t dataSetId = H5Dcreate1(fileId, "fileName", H5T_NATIVE_FLOAT, dataSpaceId, H5P_DEFAULT);
    H5Dwrite(dataSetId, H5T_NATIVE_FLOAT, H5S_ALL, H5S_ALL, H5P_DEFAULT, matrix);
    
    H5Dclose(dataSetId);
    H5Sclose(dataSpaceId);
    H5Fclose(fileId);
}

Mat readMatrix(const char *fileName) {
    
    //read fisher vectors(label-00, label-01, ...) to matrix.
    hid_t fileId = H5Fopen(fileName, H5F_ACC_RDONLY, H5P_DEFAULT);
    
    ////get dataset 1
    hid_t datasetId = H5Dopen1(fileId, "fileName");
    hid_t spaceId = H5Dget_space(datasetId);
    int ndims = H5Sget_simple_extent_ndims(spaceId);
    hsize_t dims[ndims];
    herr_t status = H5Sget_simple_extent_dims(spaceId, dims, NULL);
    
    int cap = 1;
    int rows = (int)dims[0];
    int cols = (int)dims[1];
    cap = rows*cols;
    
    Mat dataMatrix;
    dataMatrix.create(rows, cols, CV_32F);
    
    hid_t memspace = H5Screate_simple(ndims, dims, NULL);
    status = H5Dread(datasetId, H5T_NATIVE_FLOAT, memspace, spaceId, H5P_DEFAULT, dataMatrix.data);
    
    H5Sclose(spaceId);
    H5Dclose(datasetId);
    H5Fclose(fileId);
    
    return dataMatrix;
}

void *readMatrix(const char *fileName, hid_t dataType) {
    
    //read fisher vectors(label-00, label-01, ...) to matrix.
    hid_t fileId = H5Fopen(fileName, H5F_ACC_RDONLY, H5P_DEFAULT);
    
    ////get dataset 1
    hid_t datasetId = H5Dopen1(fileId, "fileName");
    hid_t spaceId = H5Dget_space(datasetId);
    int ndims = H5Sget_simple_extent_ndims(spaceId);
    hsize_t dims[ndims];
    herr_t status = H5Sget_simple_extent_dims(spaceId, dims, NULL);
    
    int cap = 1;
    int rows = (int)dims[0];
    int cols = (int)dims[1];
    cap = rows*cols;
    
    void *data = malloc(rows*cols*4);
    
    hid_t memspace = H5Screate_simple(ndims, dims, NULL);
    status = H5Dread(datasetId, dataType, memspace, spaceId, H5P_DEFAULT, data);
    
    H5Sclose(spaceId);
    H5Dclose(datasetId);
    H5Fclose(fileId);
    
    return data;
}

-(cv::Mat) softmaxW: (int)labelCount path:(const char *)path {
    
    //get softmax's weights from hdf5, which train in python
    hid_t fileId = H5Fopen(path, H5F_ACC_RDONLY, H5P_DEFAULT);
    
    ////get dataset 1
    hid_t datasetId = H5Dopen1(fileId, "softmax");
    hid_t spaceId = H5Dget_space(datasetId);
    int ndims = H5Sget_simple_extent_ndims(spaceId);
    hsize_t dims[ndims];
    herr_t status = H5Sget_simple_extent_dims(spaceId, dims, NULL);
    
    int cap = 1;
    for(int i=0; i<ndims; i++) {
        cap *= dims[i];
    }
    float *weights = (float *)malloc(sizeof(float)*cap);
    hid_t memspace = H5Screate_simple(ndims,dims,NULL);
    status = H5Dread(datasetId, H5T_NATIVE_FLOAT, memspace, spaceId, H5P_DEFAULT, weights);
    
    Mat weightMat(FV_DIMENSION, labelCount, CV_32F, weights);
    
    status = H5Sclose(spaceId);
    status = H5Dclose(datasetId);
    H5Fclose(fileId);
    return weightMat;
}

void savePCA(const std::string &file_name,cv::PCA pca_) {
    FileStorage fs(file_name,FileStorage::WRITE);
    fs << "mean" << pca_.mean;
    fs << "e_vectors" << pca_.eigenvectors;
    fs << "e_values" << pca_.eigenvalues;
    fs.release();
}

void loadPCA(const std::string &file_name,cv::PCA &pca_) {
    FileStorage fs(file_name,FileStorage::READ);
    fs["mean"] >> pca_.mean ;
    fs["e_vectors"] >> pca_.eigenvectors ;
    fs["e_values"] >> pca_.eigenvalues ;
    fs.release();
}

-(void) computeFisherVector: (Mat)descriptors means:(float *)means covariances:(float *)covariances path:(float *)priors fvMat:(Mat &)fisherVector {
    
    //input gmm model and sift descriptors, calculate fisher vector of a picture
    float *enc = (float *)vl_malloc(sizeof(float) * FV_DIMENSION);
    vl_fisher_encode(enc, VL_TYPE_FLOAT, means, SIFT_DIMENSION, GM_COUNT, covariances, priors, descriptors.data, descriptors.rows, VL_FISHER_FLAG_IMPROVED);
    fisherVector.create(1, FV_DIMENSION, CV_32F);
    memcpy(fisherVector.data, enc, sizeof(float) * FV_DIMENSION);
}

//root node has 3 centers, the penultimate layer node also has 3 centers, traverse only reach penultimate layer
//the center(uint_8) (e.g.:122) but to calculate mean, so change to uint32 in function vl_ikm_get_centers(e.g.:122,0,0,0)
void traverseTree(VlHIKMNode *node, int &subTrees, int *hikmCenters, int &count) {
    
    if(node) {
        const vl_int32 *centers = vl_ikm_get_centers(node->filter);
        for(int i=0; i<subTrees; i++) {
            memcpy(hikmCenters+count*SIFT_DIMENSION, centers+i*SIFT_DIMENSION, SIFT_DIMENSION*sizeof(vl_int32));
            count++;
        }
        if(node->children) {
            for(int k=0; k<vl_ikm_get_K(node->filter); k++) {
                traverseTree(node->children[k], subTrees, hikmCenters, count);
            }
        }
    }
}

//get the leaf node of kd-tree, and store to leafCenters, by index, vl_int32-->float, due to vlad
void getLeafCenters(VlHIKMNode *node, int &subTrees, float *leafCenters, int &count, vl_size height) {
    
    if(node) {
        const vl_int32 *centers = vl_ikm_get_centers(node->filter);
        
        if(height==1) {
            for(int i=0; i<subTrees; i++) {
                for(int j=0; j<SIFT_DIMENSION; j++) {
                    leafCenters[count*SIFT_DIMENSION + j] = (float)centers[i*SIFT_DIMENSION + j];
                }
                count++;
            }
            return;
        }
        else {
            if(node->children) {
                vl_size K = vl_ikm_get_K(node->filter);
                for(int k=0; k<K; k++) {
                    getLeafCenters(node->children[k], subTrees, leafCenters, count, height-1);
                }
            }
        }
    }
}

//init hikmTree using center data saved in HDF5
VlHIKMNode *
initTreeUsingCenters (VlHIKMTree *tree,
                      vl_int32 *data,
                      int &count, vl_size subTrees, vl_size height)
{
    VlHIKMNode *node = (VlHIKMNode *)vl_malloc (sizeof(VlHIKMNode)) ;
    node->filter = vl_ikm_new (tree->method) ;
    node->filter->K = subTrees;
    node->filter->M = SIFT_DIMENSION;
    node->filter->centers = (vl_int32 *)vl_malloc(sizeof(vl_int32) * SIFT_DIMENSION * subTrees) ;
    
    for(int i=0; i<subTrees; i++) {
        memcpy(node->filter->centers+i*SIFT_DIMENSION, data+count*SIFT_DIMENSION, SIFT_DIMENSION*sizeof(vl_int32));
        count++;
    }
    node->children = (height == 1) ? 0 : (VlHIKMNode **)vl_malloc (sizeof(*node->children) * subTrees) ;
    
    /* recursively process each child */
    if (height > 1) {
        for (vl_uindex k = 0 ; k < subTrees ; ++k) {
            node->children[k] = initTreeUsingCenters(tree, data, count, subTrees, height - 1) ;
        }
    }
    return node ;
}

Mat computeVlad(VlHIKMTree *hikmTree, int nclusters, int subTrees, int depth, float *idf, float *leafCenters, Mat descriptors) {
    
    Mat imgDescs;
    descriptors.convertTo(imgDescs, CV_8U);//uint8 to calc hikm path
    
    vl_uint32 asgn[depth*imgDescs.rows];
    vl_hikm_push(hikmTree, asgn, imgDescs.data, imgDescs.rows);
    //an image ==> 2000 sift descriptors ==> 2000 * path[0,1,0,2...]
    
    vl_uint32 indexes[imgDescs.rows];
    
    for(int descIdx=0; descIdx<imgDescs.rows; descIdx++) {  //each path[0,1,2,0,1]
        
        int index = 0;
        for(int i=0; i<depth; i++) {    //calculate index of leaf node
            vl_uint32 sgn = asgn[descIdx*depth+i];
            int multy = (int)pow(subTrees, depth-i-1);
            index += multy * sgn;
        }
        indexes[descIdx] = index;
    }
//    float assignments[imgDescs.rows * nclusters];
    float *assignments = (float *)malloc(imgDescs.rows * nclusters * sizeof(float));
    memset(assignments, 0, sizeof(float) * imgDescs.rows * nclusters);
    for(int i = 0; i < imgDescs.rows; i++) {  //oneHot vector(idf)
        assignments[i * nclusters + indexes[i]] = 1.;
    }
    
    descriptors.convertTo(imgDescs, CV_32F);//float to calc vlad encoder
    
    float vladEnc[SIFT_DIMENSION * nclusters];
    vl_vlad_encode(vladEnc, VL_TYPE_FLOAT, leafCenters, SIFT_DIMENSION, nclusters, imgDescs.data, imgDescs.rows, assignments, VL_VLAD_FLAG_UNNORMALIZED);
    free(assignments);
    for(int i=0; i<nclusters; i++) {  //each cluster
        for(int j=0; j<SIFT_DIMENSION; j++) {
            vladEnc[i*SIFT_DIMENSION + j] *= idf[i];
        }
    }
    
    //L2 normalize
    float sum = 0;
    for(int vladOne=0; vladOne<SIFT_DIMENSION*nclusters; vladOne++) {
        sum += pow(vladEnc[vladOne], 2);
    }
    sum = sqrt(sum);
    for(int vladOne=0; vladOne<SIFT_DIMENSION*nclusters; vladOne++) {//L2 normalize
        vladEnc[vladOne] = vladEnc[vladOne]/sum;
    }
    
    Mat vladVector;   //one picture's fisher vector
    vladVector.create(1, SIFT_DIMENSION * nclusters, CV_32F);
    memcpy(vladVector.data, vladEnc, sizeof(float) * SIFT_DIMENSION * nclusters);
    
    return vladVector;
}

@end
