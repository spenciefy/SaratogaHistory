//
//  SHImageScrollerView.h
//  SaratogaHistory
//
//  Created by Xiaolan Zhou on 6/21/15.
//  Copyright © 2015 Spencer Yen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol SHImageScrollerViewDelegate <NSObject>

@optional

- (void)SHImageScrollerViewDidTap:(NSUInteger)index;

@end

@interface SHImageScrollerView : UIView <UIScrollViewDelegate> {
    CGRect viewSize;
    UIScrollView *scrollView;
    NSArray *imageArray;
    UIPageControl *pageControl;
    int currentPageIndex;
    id<SHImageScrollerViewDelegate> delegate;
}

@property (nonatomic, retain)id<SHImageScrollerViewDelegate> delegate;

-(id)initWithFrame:(CGRect)frame imageArray:(NSArray *)imgArr;


@end
