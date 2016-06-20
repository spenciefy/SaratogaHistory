//
//  SHImageScrollerView.m
//  SaratogaHistory
//
//  Created by Richard Liu on 6/21/15.
//  Copyright © 2015 Spencer Yen. All rights reserved.
//

#import "SHImageScrollerView.h"

@implementation SHImageScrollerView
@synthesize delegate;

-(id)initWithFrame:(CGRect)frame imageArray:(NSArray *)imgArr limitImagesToOne:(BOOL)limitToOne {

    if ((self=[super initWithFrame:frame])) {
        self.userInteractionEnabled = YES;
        
//        if(limitToOne) {
//            imageArray = @[[imgArr firstObject]];
//
//        } else {
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:imgArr];
            [tempArray insertObject:[imgArr objectAtIndex:([imgArr count] - 1)] atIndex:0];
            [tempArray addObject: [imgArr objectAtIndex:0]];
            imageArray = [NSArray arrayWithArray:tempArray];
   //     }
        
        viewSize = frame;
        NSUInteger pageCount = [imageArray count];
        scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, viewSize.size.width, viewSize.size.height)];
        
        scrollView.pagingEnabled = YES;
        scrollView.contentSize = CGSizeMake(viewSize.size.width * pageCount, viewSize.size.height);
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.scrollsToTop = NO;
        scrollView.delegate = self;
        
        for (int i = 0; i < pageCount; i++) {
            UIImageView *imgView = [[UIImageView alloc] init];
            UIImage *scaledImage = [self scaleImage:[UIImage imageWithContentsOfFile:imageArray[i]] toSize:viewSize.size];
            [imgView setImage:scaledImage];
            
            [imgView setFrame:CGRectMake(viewSize.size.width * i, 0, viewSize.size.width, viewSize.size.height)];

            imgView.tag = i;
            imgView.contentMode = UIViewContentModeScaleAspectFill;

            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imagePressed:)];
            [tap setNumberOfTapsRequired:1];
            [tap setNumberOfTouchesRequired:1];
            imgView.userInteractionEnabled = YES;
            [imgView addGestureRecognizer:tap];
            [scrollView addSubview:imgView];
        }
        
        [scrollView setContentOffset:CGPointMake(viewSize.size.width, 0)];
        [self addSubview:scrollView];
              
        float pageControlWidth = (pageCount-2) * 10.0f + 40.f;
        float pagecontrolHeight = 20.0f;
        pageControl=[[UIPageControl alloc]initWithFrame:CGRectMake((self.frame.size.width-pageControlWidth),6, pageControlWidth, pagecontrolHeight)];
        pageControl.currentPage = 0;
        pageControl.numberOfPages = (pageCount-2);
        [self addSubview:pageControl];
    }
    
    return self;
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    currentPageIndex=page;
    
    pageControl.currentPage=(page - 1);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)_scrollView {
    if (currentPageIndex==0) {
        [_scrollView setContentOffset:CGPointMake(([imageArray count]-2)*viewSize.size.width, 0)];
    }
    if (currentPageIndex==([imageArray count]-1)) {
        [_scrollView setContentOffset:CGPointMake(viewSize.size.width, 0)];
    }
}

- (void)imagePressed:(UITapGestureRecognizer *)sender {
    if ([delegate respondsToSelector:@selector(SHImageScrollerViewDidTap:)]) {
        [delegate SHImageScrollerViewDidTap:sender.view.tag];
    }
}

- (UIImage*)scaleImage:(UIImage*)image toSize:(CGSize)newSize {
    CGSize scaledSize = newSize;
    float scaleFactor = 1.0;
    if(image.size.width > image.size.height ) {
        scaleFactor = image.size.width / image.size.height;
        scaledSize.width = newSize.width;
        scaledSize.height = newSize.height * scaleFactor;
    } else {
        scaledSize = image.size;
    }
    
    UIGraphicsBeginImageContextWithOptions( scaledSize, NO, 0.0 );
    CGRect scaledImageRect = CGRectMake(0.0, 0.0, scaledSize.width, scaledSize.height);
    [image drawInRect:scaledImageRect];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

@end
