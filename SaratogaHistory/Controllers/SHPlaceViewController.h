//
//  SHPlaceViewController.h
//  Saratoga History
//
//  Created by Richard Liu on 6/21/15.
//  Copyright (c) 2015 Richard Liu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SHPlace.h"

@protocol SHPlaceViewControllerDelegate;

@interface SHPlaceViewController : UIViewController <UIScrollViewDelegate >

@property (nonatomic, weak) id <SHPlaceViewControllerDelegate> delegate;
@property (strong, nonatomic) SHPlace *place;
@property (nonatomic, assign) int pageIndex;
@property (nonatomic, assign) BOOL expanded;
@property (nonatomic, assign) BOOL isTourCard;

@end

@protocol SHPlaceViewControllerDelegate <NSObject>

-(void)scrollViewDidScroll:(UIScrollView *)scrollView placeView:(SHPlaceViewController *)placeVC;

@end
