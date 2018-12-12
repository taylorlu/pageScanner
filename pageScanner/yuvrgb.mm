#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "yuvrgb.h"

#include <opencv2/imgproc/imgproc.hpp>
#import <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>

void YUV420toRGB(uint8_t *yuv,int *dst,int width, int height)
{

	unsigned char clp1[sizeof(unsigned char)*1024];
    unsigned char *clp = clp1;
    
	long int crv_tab[256];

	long int cbu_tab[256];
	long int cgu_tab[256];

	long int cgv_tab[256];
	long int tab_76309[256];

	long int crv, cbu, cgu, cgv;
	int i;

	crv = 104597;
	cbu = 132201;
	cgu = 25675;
	cgv = 53279;

	for (i = 0; i < 256; i++)
	{
		crv_tab[i] = (i - 128) * crv;
		cbu_tab[i] = (i - 128) * cbu;
		cgu_tab[i] = (i - 128) * cgu;
		cgv_tab[i] = (i - 128) * cgv;
		tab_76309[i] = 76309 * (i - 16);
	}

//	clp = (unsigned char *)malloc(sizeof(unsigned char)*1024);

//	clp1 = clp;

	clp += 384;

	for (i = -384; i < 640; i++)
		clp[i] = (i < 0) ? 0 : ((i > 255) ? 255 : i);

	int y11, y21;
	int y12, y22;
	int y13, y23;
	int y14, y24;
	int u, v;
	int j;
	int c11, c21, c31, c41;
	int c12, c22, c32, c42;
	unsigned int DW;
	unsigned int *id1, *id2;
	unsigned char *py1, *py2, *pu, *pv;

	py1 = yuv;                  //y分量内存
	pu = py1+width*height;      //u分量内存
	pv = pu+width*height/4;     //v分量内存
	py2 = py1 + width;          //第2行y分量

	id1 = (unsigned int *)dst;  //目标rgb数据内存
	id2 = id1 + width;          //第二行rgb

	for (j = 0; j < height; j += 2) //2行扫描一次
	{
		/* line j + 0 */
		for (i = 0; i < width; i += 4)  //一次处理4个，RGBr gbRG Brgb
		{
			u = *pu++;
			v = *pv++;
			c11 = crv_tab[v];
			c21 = cgu_tab[u];
			c31 = cgv_tab[v];
			c41 = cbu_tab[u];

			u = *pu++;
			v = *pv++;
			c12 = crv_tab[v];
			c22 = cgu_tab[u];
			c32 = cgv_tab[v];
			c42 = cbu_tab[u];

			y11 = tab_76309[*py1++];  /* (255/219)*65536 */
			y12 = tab_76309[*py1++];
			y13 = tab_76309[*py1++];  /* (255/219)*65536 */
			y14 = tab_76309[*py1++];

			y21 = tab_76309[*py2++];
			y22 = tab_76309[*py2++];
			y23 = tab_76309[*py2++];
			y24 = tab_76309[*py2++];

			/* RGBR */
			DW = ((clp[(y11 + c41) >> 16])) |
				((clp[(y11 - c21 - c31) >> 16]) << 8) |
				((clp[(y11 + c11) >> 16]) << 16) |
				(0xff000000);
			*id1++ = DW;

			/* GBRG */
			DW = (0xff000000) |
				((clp[(y12 + c41) >> 16]) ) |
				((clp[(y12 - c21 - c31) >> 16])<<8) |
				((clp[(y12 + c11) >> 16]) << 16);
			*id1++ = DW;

			/* BRGB */

			DW = (0xff000000) |
				((clp[(y13 + c12) >> 16])<<16) |
				((clp[(y13 - c22 - c32) >> 16]) << 8) |
				((clp[(y13 + c42) >> 16]));
			*id1++ = DW;

			DW = (0xff000000) |
				((clp[(y14 + c42) >> 16]) ) |
				((clp[(y14 - c22 - c32) >> 16]) << 8) |
				((clp[(y14 + c12) >> 16]) << 16);
			*id1++ = DW;

			//=============================

			/* RGBR */
			DW = (0xff000000) |
				((clp[(y21 + c11) >> 16]) << 16) |
				((clp[(y21 - c21 - c31) >> 16]) << 8) |
				((clp[(y21 + c41) >> 16]));
			*id2++ = DW;

			/* GBRG */
			DW = (0xff000000) |
				((clp[(y22 + c41) >> 16]) ) |
				((clp[(y22 - c21 - c31) >> 16])<<8) |
				((clp[(y22 + c11) >> 16]) << 16);
			*id2++ = DW;

			/* BRGB */
			DW = (0xff000000) |
				((clp[(y23 + c42) >> 16]) ) |
				((clp[(y23 - c22 - c32) >> 16]) << 8) |
				((clp[(y23 + c12) >> 16])<<16);
			*id2++ = DW;

			DW = (0xff000000) |
				((clp[(y24 + c42) >> 16]) ) |
				((clp[(y24 - c22 - c32) >> 16]) << 8) |
				((clp[(y24 + c12) >> 16]) << 16);
			*id2++ = DW;

		}

		id1 += width;
		id2 += width;

		py1 += width;
		py2 += width;
	}

//	free(clp1);
//	clp1 = NULL;
//	clp = NULL;
}

void yuvReSize(uint8_t *yuv,uint8_t *dst,int width, int height, int dstHeight, int dstWidth) {
    IplImage *yImg = cvCreateImage(cvSize(width,height),IPL_DEPTH_8U,1);
    IplImage *uImg = cvCreateImage(cvSize(width/2,height/2),IPL_DEPTH_8U,1);
    IplImage *vImg = cvCreateImage(cvSize(width/2,height/2),IPL_DEPTH_8U,1);
    IplImage *yDstImg = cvCreateImage(cvSize(dstWidth,dstHeight),IPL_DEPTH_8U,1);
    IplImage *uDstImg = cvCreateImage(cvSize(dstWidth/2,dstHeight/2),IPL_DEPTH_8U,1);
    IplImage *vDstImg = cvCreateImage(cvSize(dstWidth/2,dstHeight/2),IPL_DEPTH_8U,1);
    memcpy(yImg->imageData,yuv,width*height);
    memcpy(uImg->imageData,yuv+width*height,width*height/4);
    memcpy(vImg->imageData,yuv+width*height+width*height/4,width*height/4);
    cvResize(yImg,yDstImg,CV_INTER_LINEAR);
    cvResize(uImg,uDstImg,CV_INTER_LINEAR);
    cvResize(vImg,vDstImg,CV_INTER_LINEAR);
    memcpy(dst,yDstImg->imageData,dstWidth*dstHeight);
    memcpy(dst+dstWidth*dstHeight,uDstImg->imageData,dstWidth*dstHeight/4);
    memcpy(dst+dstWidth*dstHeight+dstWidth*dstHeight/4,vDstImg->imageData,dstWidth*dstHeight/4);
    cvReleaseImage(&yImg);
    cvReleaseImage(&uImg);
    cvReleaseImage(&vImg);
    cvReleaseImage(&yDstImg);
    cvReleaseImage(&uDstImg);
    cvReleaseImage(&vDstImg);
}

