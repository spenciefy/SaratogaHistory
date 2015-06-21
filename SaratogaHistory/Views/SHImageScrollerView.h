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
-(void)SHImageScrollerViewDidClicked:(NSUInteger)index;
@end

@interface SHImageScrollerView : UIView <UIScrollViewDelegate> {
    CGRect viewSize;
    UIScrollView *scrollView;
    NSArray *imageArray;
    NSArray *captionArray;
    UIPageControl *pageControl;
    id<SHImageScrollerViewDelegate> delegate;
}

@property (nonatomic, retain)id<SHImageScrollerViewDelegate> delegate;

-(id)initWithFrame:(CGRect)frame ImageArray:(NSArray *)imgArr CaptionArray:(NSArray *)capArr;

@end
