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

-(id)initWithFrame:(CGRect)frame imageArray:(NSArray *)imgArr captionArray:(NSArray *)capArr; {
    if ((self=[super initWithFrame:frame])) {
        
        self.userInteractionEnabled = YES;
        
        captionArray = capArr;
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:imgArr];
        [tempArray insertObject:[imgArr objectAtIndex:([imgArr count] -1)] atIndex:0];
        [tempArray addObject: [imgArr objectAtIndex:0]];
        imageArray = [NSArray arrayWithArray:tempArray];
        
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
            UIImageView *imgView=[[UIImageView alloc] init];
            imgView.contentMode = UIViewContentModeScaleAspectFill;
            
            UIImage *image = [self scaleImage:[UIImage imageWithContentsOfFile:imageArray[i]] toSize:viewSize.size];
//            //CGSize newSize = CGSizeMake(frame., scrollView.frame.size.width);
//            UIGraphicsBeginImageContext(frame.size);
//            [image drawInRect:CGRectMake(0,0,frame.size.width,frame.size.height+200)];
//            UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
//            UIGraphicsEndImageContext(); 
            [imgView setImage:image];
            
            [imgView setFrame:CGRectMake(viewSize.size.width * i, 0, viewSize.size.width * i, viewSize.size.height)];
            imgView.tag = i;
            UITapGestureRecognizer *tap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imagePressed:)];
            [tap setNumberOfTapsRequired:1];
            [tap setNumberOfTouchesRequired:1];
            imgView.userInteractionEnabled=YES;
            [imgView addGestureRecognizer:tap];
            [scrollView addSubview:imgView];
        }
        
        [scrollView setContentOffset:CGPointMake(viewSize.size.width, 0)];
        [self addSubview:scrollView];
        
        UIView *noteView=[[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height-33,self.bounds.size.width,33)];
        [noteView setBackgroundColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.8]];
        
        float pageControlWidth=(pageCount-2)*10.0f+40.f;
        float pagecontrolHeight=20.0f;
        pageControl=[[UIPageControl alloc]initWithFrame:CGRectMake((self.frame.size.width-pageControlWidth),6, pageControlWidth, pagecontrolHeight)];
        pageControl.currentPage=0;
        pageControl.numberOfPages=(pageCount-2);
        [noteView addSubview:pageControl];
        
        noteTitle=[[UILabel alloc] initWithFrame:CGRectMake(5, 6, self.frame.size.width-pageControlWidth-15, 20)];
        [noteTitle setText:[capArr objectAtIndex:0]];
        [noteTitle setBackgroundColor:[UIColor clearColor]];
        [noteTitle setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:14]];
        noteTitle.textColor=  [UIColor whiteColor];
        [noteView addSubview:noteTitle];
        
        [self addSubview:noteView];
    }
    return self;
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    currentPageIndex=page;
    
    pageControl.currentPage=(page - 1);
    int captionIndex=page - 1;
    if (captionIndex == [captionArray count]) {
        captionIndex = 0;
    }
    if (captionIndex<0) {
        captionIndex = (int)[captionArray count]-1;
    }
    [noteTitle setText:[captionArray objectAtIndex:captionIndex]];
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

- (UIImage*) scaleImage:(UIImage*)image toSize:(CGSize)newSize {
    CGSize scaledSize = newSize;
    float scaleFactor = 1.0;
    if( image.size.width > image.size.height ) {
        scaleFactor = image.size.width / image.size.height;
        scaledSize.width = newSize.width;
        scaledSize.height = newSize.height / scaleFactor;
    }
    else {
        scaleFactor = image.size.height / image.size.width;
        scaledSize.height = newSize.height;
        scaledSize.width = newSize.width / scaleFactor;
    }
    
    UIGraphicsBeginImageContextWithOptions( scaledSize, NO, 0.0 );
    CGRect scaledImageRect = CGRectMake( 0.0, 0.0, scaledSize.width, scaledSize.height );
    [image drawInRect:scaledImageRect];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

@end
