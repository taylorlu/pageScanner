//
//  yuvrgb.h
//  pageScanner
//
//  Created by LuDong on 2018/2/28.
//  Copyright © 2018年 LuDong. All rights reserved.
//

#ifndef yuvrgb_h
#define yuvrgb_h

void yuvReSize(uint8_t *yuv,uint8_t *dst,int width, int height, int dstHeight, int dstWidth);
void YUV420toRGB(uint8_t *yuv,int *dst,int width, int height);

#endif /* yuvrgb_h */
