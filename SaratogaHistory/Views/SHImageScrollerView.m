//
//  SHImageScrollerView.m
//  SaratogaHistory
//
//  Created by Richard Liu on 6/21/15.
//  Copyright © 2015 Spencer Yen. All rights reserved.
//

#import "SHImageScrollerView.h"
#import <KASlideShow/KASlideShow.h>

@implementation SHImageScrollerView
@synthesize delegate;

-(id)initWithFrame:(CGRect)frame imageArray:(NSArray *)imgArr; {
    KASlideShow *slideshow = [[KASlideShow alloc] initWithFrame:frame];
    [slideshow setDelay:3];                                            // Delay between transitions
    [slideshow setTransitionDuration:1];                               // Transition duration
    [slideshow setTransitionType:KASlideShowTransitionFade];           // Choose a transition type (fade or slide)
    [slideshow setImagesContentMode:UIViewContentModeScaleAspectFill]; // Choose a content mode to display images
    [slideshow addImagesFromResources:imgArr];                         // Add images from resources
    [slideshow addGesture:KASlideShowGestureTap];                      // Gesture to go previous/next on the image
    return self;
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    
}

- (void)imagePressed:(UITapGestureRecognizer *)sender {
    if ([delegate respondsToSelector:@selector(SHImageScrollerViewDidTap:)]) {
        [delegate SHImageScrollerViewDidTap:sender.view.tag];
    }
}

@end
