//
//  SHPlaceViewController.m
//  Saratoga History
//
//  Created by Richard Liu on 12/26/14.
//  Copyright (c) 2015 Richard Liu. All rights reserved.
//

#import "SHPlaceViewController.h"
#import "SHImageScrollerView.h"
#import <IDMPhotoBrowser/IDMPhotoBrowser.h>

@interface SHPlaceViewController () <SHImageScrollerViewDelegate>

@end

@implementation SHPlaceViewController {
    UIScrollView *_scrollView;
    UILabel *_captionLabel;
    UITextView *_textView;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.expanded = NO;
    self.view.layer.cornerRadius = 12;
    self.view.layer.masksToBounds = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pause)
                                                 name:@"PageViewChange"
                                               object:nil];
    
    _captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 15, 40)];
    _captionLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:22.0f];
    _captionLabel.center = CGPointMake(self.view.frame.size.width/2, 25);
    _captionLabel.textAlignment = NSTextAlignmentLeft;
    _captionLabel.text = self.place.placeTitle;
    [self.view addSubview:_captionLabel];
    
    SYAudioPlayerView *audioPlayer = [[SYAudioPlayerView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width - 10, 45) audioFileURL:self.place.audioURLAsset.URL autoplay:NO];
    audioPlayer.center = CGPointMake(self.view.frame.size.width/2, 48);
    
    if(self.showsAudioView) {
        [self.view addSubview:audioPlayer];
        _scrollView = [[UIScrollView alloc] initWithFrame: CGRectMake(0, audioPlayer.frame.origin.y + audioPlayer.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - 130)];
    } else {
        _scrollView = [[UIScrollView alloc] initWithFrame: CGRectMake(0, audioPlayer.frame.origin.y + audioPlayer.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - 82)];
    }

    _scrollView.showsVerticalScrollIndicator = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.scrollEnabled = YES;
    _scrollView.userInteractionEnabled = YES;
    _scrollView.delegate = self;
    [self.view addSubview:_scrollView];
    
    SHImageScrollerView *imageScroller = [[SHImageScrollerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 170) imageArray:self.place.images captionArray:self.place.imageCaptions];
    imageScroller.delegate = self;
    [_scrollView addSubview:imageScroller];
    
    _textView = [[UITextView alloc] initWithFrame: self.view.frame];
    NSAttributedString *text = [[NSAttributedString alloc] initWithString:self.place.descriptionText attributes:@{NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-Regular" size:17]}];
    _textView.frame = CGRectMake(8, imageScroller.frame.origin.y + imageScroller.frame.size.height + 10, self.view.frame.size.width - 16, [self textViewHeightForAttributedText:text andWidth:self.view.frame.size.width-16]);
    _textView.scrollEnabled = NO;
    _textView.editable = NO;
    _textView.text = self.place.descriptionText;
    _textView.font = [UIFont fontWithName:@"AvenirNext-Regular" size:17];
    _textView.backgroundColor = [UIColor whiteColor];
    [_scrollView addSubview: _textView];
    
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, _textView.frame.origin.y + _textView.frame.size.height);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)textViewHeightForAttributedText: (NSAttributedString*)text andWidth: (CGFloat)width {
    UITextView *calculationView = [[UITextView alloc] init];
    [calculationView setAttributedText:text];
    CGSize size = [calculationView sizeThatFits:CGSizeMake(width, FLT_MAX)];
    return size.height;
}

- (void)pause {
    [self.playerView stopAudio:self];
}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if ([_delegate respondsToSelector:@selector(scrollViewDidScroll:placeView:)]) {
        [_delegate scrollViewDidScroll:scrollView placeView:self];
    }
}
-(CGSize) getContentSize:(UITextView*) myTextView{
    return [myTextView sizeThatFits:CGSizeMake(myTextView.frame.size.width, FLT_MAX)];
}

- (void)SHImageScrollerViewDidTap:(NSUInteger)index {
    NSLog(@"tapped");
    // URLs array
    NSArray *photosURL = @[[NSURL URLWithString:@"http://farm4.static.flickr.com/3567/3523321514_371d9ac42f_b.jpg"],
                           [NSURL URLWithString:@"http://farm4.static.flickr.com/3629/3339128908_7aecabc34b_b.jpg"],
                           [NSURL URLWithString:@"http://farm4.static.flickr.com/3364/3338617424_7ff836d55f_b.jpg"],
                           [NSURL URLWithString:@"http://farm4.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg"]];
    //NSArray *captions = @[@"Caption 1", @"another caption", @"blah", @"more stuff"];
    
    // Create an array to store IDMPhoto objects
    NSMutableArray *photos = [NSMutableArray new];
    
    int i = 0;
    for (NSURL *url in photosURL) {
        IDMPhoto *photo = [IDMPhoto photoWithURL:url];
        photo.caption = [self.place.imageCaptions objectAtIndex:i];
        [photos addObject:photo];
        if (i < 1) {
            i++;
        }
    }
    
    // make it number of items, not const
    //for (int i = 0; i < 4; i++) {
    //
    //}z
    
    // TODO: look at for captions: self.place.imageCaptions
    
    // Or use this constructor to receive an NSArray of IDMPhoto objects from your NSURL objects
    //NSArray *IDMphotos = [IDMPhoto photosWithURLs:photosURL];
    
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
    browser.displayActionButton = NO;
    [self presentViewController:browser animated:YES completion:nil];

}

@end