//
//  SHPlaceViewController.m
//  Saratoga History
//
//  Created by Richard Liu on 6/21/15.
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
    
    SYAudioPlayerView *audioPlayer = [[SYAudioPlayerView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width - 10, 45) audioFileURL:self.place.audioURLAsset.URL autoplay:NO textColor: NULL];
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

    // IDMPhoto array
    NSArray *IDMphotos = [IDMPhoto photosWithFilePaths:self.place.images];
    // Iterate through IDMPhoto objects and add captions
    for (int i = 0; i < IDMphotos.count; i++){
        IDMPhoto *photo = IDMphotos[i];
        photo.caption = self.place.imageCaptions[i];
    }
    
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:IDMphotos];
    browser.displayActionButton = NO;
    browser.displayArrowButton = NO;
    [self presentViewController:browser animated:YES completion:nil];
}

@end