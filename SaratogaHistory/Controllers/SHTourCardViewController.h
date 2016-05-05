//
//  SHTourCardViewController.h
//  Saratoga History
//
//  Created by Aakash Thumaty on 9/13/15.
//  Copyright © 2015 Aakash Thumaty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SHPlace.h"
#import "SYAudioPlayerView.h"

@protocol SHPlaceViewControllerDelegate;

@interface SHTourCardViewController : UIViewController

@property (nonatomic, weak) id <SHPlaceViewControllerDelegate> delegate;

@property (nonatomic, assign) int pageIndex;
@property (nonatomic, assign) BOOL expanded;

@end




@protocol SHPlaceViewControllerDelegate;

@interface SHPlaceViewController : UIViewController <UIScrollViewDelegate >

@property (nonatomic, weak) id <SHPlaceViewControllerDelegate> delegate;
@property (strong, nonatomic) SHPlace *place;
@property (nonatomic, assign) int pageIndex;
@property (nonatomic, assign) BOOL expanded;
@property (nonatomic, assign) BOOL showsAudioView;

@property (strong, nonatomic) SYAudioPlayerView *playerView;

- (void)pause;

@end

@protocol SHPlaceViewControllerDelegate <NSObject>

-(void)scrollViewDidScroll:(UIScrollView *)scrollView placeView:(SHPlaceViewController *)placeVC;

@end
