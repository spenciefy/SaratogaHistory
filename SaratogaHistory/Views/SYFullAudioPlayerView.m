//
//  SYFullAudioPlayerView.m
//  Saratoga History
//
//  Created by Richard Liu on 1/4/15.
//  Copyright (c) 2015 Spencer Yen. All rights reserved.
//

#import "SYFullAudioPlayerView.h"
#import "UIView+AutoLayout.h"

@implementation SYFullAudioPlayerView

- (id)initWithFrame:(CGRect)frame audioFileURL:(NSURL *)fileURL autoplay:(BOOL)autoplay textColor:(UIColor *)textColor {
    self = [super initWithFrame:frame];
    self.autoplay = autoplay;
    self.textColor = textColor;
    
    //Set default text color to black
    if (textColor == NULL) {
        self.textColor = [UIColor blackColor];
    }
    
    // Setup audioPlayer
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    [_audioPlayer prepareToPlay];
    
    // Setup buttons
    _playButton = [UIButton new];
    _playButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_playButton addTarget:self action:@selector(playAudio:) forControlEvents:UIControlEventTouchUpInside];
    [_playButton setImage:[UIImage imageNamed:@"play-icon"] forState:UIControlStateNormal];
    [self addSubview:_playButton];
    
    _stopButton = [UIButton new];
    _stopButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_stopButton addTarget:self action:@selector(stopAudio:) forControlEvents:UIControlEventTouchUpInside];
    [_stopButton setImage:[UIImage imageNamed:@"pause-icon"] forState:UIControlStateNormal];
    [self.stopButton setHidden:YES];
    [self addSubview:_stopButton];
    
    _previousButton = [UIButton new];
    _previousButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_previousButton addTarget:self action:@selector(previousTrack) forControlEvents:UIControlEventTouchUpInside];
    [_previousButton setTitle:@"Previous Place" forState:UIControlStateNormal];
    [_previousButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    _previousButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    _previousButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.f];
    _previousButton.titleLabel.numberOfLines = 1;
    [self addSubview:_previousButton];
    
    _nextButton = [UIButton new];
    _nextButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_nextButton addTarget:self action:@selector(nextTrack) forControlEvents:UIControlEventTouchUpInside];
    [_nextButton setTitle:@"Next Place" forState:UIControlStateNormal];
    [_nextButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    _nextButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    _nextButton.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.f];
    _nextButton.titleLabel.numberOfLines = 1;
    [self addSubview:_nextButton];
    
    _endTour = [UIButton new];
    _endTour.translatesAutoresizingMaskIntoConstraints = NO;
    [_endTour addTarget:self action:@selector(dismissTour) forControlEvents:UIControlEventTouchUpInside];
    [_endTour setTitle:@"End Tour" forState:UIControlStateNormal];
    [_endTour setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    _endTour.titleLabel.textAlignment = NSTextAlignmentRight;
    _endTour.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.f];
    _endTour.titleLabel.numberOfLines = 1;
    [self addSubview:_endTour];
    
    
    // Setup seekbar
    _seekBar = [UISlider new];
    _seekBar.translatesAutoresizingMaskIntoConstraints = NO;
    [_seekBar addTarget:self action:@selector(updateSlider:) forControlEvents:UIControlEventValueChanged];
    _seekBar.minimumValue = 0.0;
    _seekBar.maximumValue = _audioPlayer.duration;
    _seekBar.value = 0.0;
    CGRect rect = CGRectMake(0, 0, 1, 3);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [[UIColor lightGrayColor] setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [_seekBar setMinimumTrackImage:image forState:UIControlStateNormal];
    [_seekBar setMinimumTrackImage:image forState:UIControlStateNormal];
    
    [_seekBar setThumbImage:[self thumbImageForColor:[UIColor colorWithRed:211/255.0 green:84/255.0 blue:0/255.0 alpha:1.0]] forState:UIControlStateNormal];
    [_seekBar setThumbImage:[self thumbImageForColor:[UIColor colorWithRed:211/255.0 green:84/255.0 blue:0/255.0 alpha:1.0]] forState:UIControlStateHighlighted];
    
    [self addSubview:_seekBar];
    
    // Setup labels
    
    _placeLabel = [UILabel new];
    _placeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _placeLabel.textColor = [UIColor blackColor];
    _placeLabel.textAlignment = NSTextAlignmentLeft;
    _placeLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:20];
    [self addSubview:_placeLabel];

    _currentTime = [UILabel new];
    _currentTime.translatesAutoresizingMaskIntoConstraints = NO;
    _currentTime.text = @"0:00";
    _currentTime.textColor = self.textColor;
    _currentTime.textAlignment = NSTextAlignmentLeft;
    _currentTime.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    [self addSubview:_currentTime];
    
    _endTime = [UILabel new];
    _endTime.translatesAutoresizingMaskIntoConstraints = NO;
    NSTimeInterval totalTime = self.audioPlayer.duration;
    int min1= totalTime/60;
    int sec1= lroundf(totalTime) % 60;
    
    NSString *secStr1 = [NSString stringWithFormat:@"%d", sec1];
    if (secStr1.length == 1) {
        secStr1 = [NSString stringWithFormat:@"0%d", sec1];
    }
    _endTime.text = [NSString stringWithFormat:@"-%d:%@", min1, secStr1];
    _endTime.textColor = self.textColor;
    _endTime.textAlignment = NSTextAlignmentRight;
    _endTime.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    [self addSubview:_endTime];
    
    /*
     *  Setup views using autolayout. Pin labels and status bar to the bottom of the view and
     *  pin the play and stop buttons to the top of the view.
     */
    
    [self.playButton pinToSuperviewEdges:JRTViewPinTopEdge inset:25];
    [self.playButton pinToSuperviewEdges:JRTViewPinLeftEdge inset:12];
    [self.playButton constrainToWidth:30.0];
    [self.playButton constrainToHeight:30.0];
    
    [self.stopButton pinToSuperviewEdges:JRTViewPinTopEdge inset:25];
    [self.stopButton pinToSuperviewEdges:JRTViewPinLeftEdge inset:12];
    [self.stopButton constrainToWidth:30.0];
    [self.stopButton constrainToHeight:30.0];
    
    [self.placeLabel pinAttribute:NSLayoutAttributeCenterY toAttribute:NSLayoutAttributeCenterY ofItem:self.playButton withConstant:1.f];
    [self.placeLabel constrainToWidth:self.frame.size.width-50.f];
    [self.placeLabel pinAttribute:NSLayoutAttributeLeading toAttribute:NSLayoutAttributeTrailing ofItem:self.playButton withConstant:10.f];
    
    [self.currentTime pinAttribute:NSLayoutAttributeCenterY toAttribute:NSLayoutAttributeCenterY ofItem:self.seekBar];
    [self.currentTime pinToSuperviewEdges:JRTViewPinLeftEdge inset:15];
    [self.currentTime constrainToWidth:30];
    [self.currentTime constrainToHeight:20];
    
    [self.seekBar pinAttribute:NSLayoutAttributeTop toAttribute:NSLayoutAttributeBottom ofItem:self.playButton withConstant:7.5f];
    [self.seekBar constrainToWidth:self.frame.size.width-105];
    [self.seekBar pinAttribute:NSLayoutAttributeLeading toAttribute:NSLayoutAttributeTrailing ofItem:self.currentTime withConstant:2.f];
    
    [self.endTime pinAttribute:NSLayoutAttributeCenterY toAttribute:NSLayoutAttributeCenterY ofItem:self.seekBar];
    [self.endTime pinAttribute:NSLayoutAttributeLeading toAttribute:NSLayoutAttributeTrailing ofItem:self.seekBar withConstant:5.f];
    [self.endTime constrainToWidth:30];
    
    [self.previousButton pinAttribute:NSLayoutAttributeTop toAttribute:NSLayoutAttributeBottom ofItem:self.currentTime withConstant:4.f];
    [self.previousButton pinToSuperviewEdges:JRTViewPinLeftEdge inset:15];
    [self.previousButton constrainToHeight:23.0];
    
    [self.nextButton pinAttribute:NSLayoutAttributeTop toAttribute:NSLayoutAttributeBottom ofItem:self.currentTime withConstant:4.f];
    [self.nextButton pinAttribute:NSLayoutAttributeLeading toAttribute:NSLayoutAttributeTrailing ofItem:self.previousButton withConstant:10.f];
    [self.nextButton constrainToHeight:23.0];
    
    [self.endTour pinAttribute:NSLayoutAttributeTop toAttribute:NSLayoutAttributeBottom ofItem:self.currentTime withConstant:4.f];
    [self.endTour pinToSuperviewEdges:JRTViewPinRightEdge inset:13.f];
    [self.endTour constrainToHeight:23.0];
    [self.endTour constrainToWidth:80.f];
    
    
    //Autoplay
    if (self.autoplay == YES) {
        self.playButton.hidden = YES;
        self.stopButton.hidden = NO;
        [self.audioPlayer play];
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
    }
    
    return self;
}

- (void)updateTime:(NSTimer *)timer {
    NSTimeInterval timePassed = self.audioPlayer.currentTime;
    int min= timePassed/60;
    int sec= lroundf(timePassed) % 60;
    NSTimeInterval totalTime = self.audioPlayer.duration;
    int min1= totalTime/60;
    int sec1= lroundf(totalTime-timePassed) % 60;
    
    // If seconds is under 10 put a zero before the second value
    NSString *secStr = [NSString stringWithFormat:@"%d", sec];
    if (secStr.length == 1) {
        secStr = [NSString stringWithFormat:@"0%d", sec];
    }
    
    NSString *secStr1 = [NSString stringWithFormat:@"%d", sec1];
    if (secStr1.length == 1) {
        secStr1 = [NSString stringWithFormat:@"0%d", sec1];
    }
    
    self.currentTime.text = [NSString stringWithFormat:@"%d:%@", min, secStr];
    self.endTime.text = [NSString stringWithFormat:@"-%d:%@", min1, secStr1];
    
    self.seekBar.value = self.audioPlayer.currentTime;
    if (self.audioPlayer.currentTime == self.audioPlayer.duration) {
        self.playButton.hidden = NO;
        self.stopButton.hidden = YES;
        [timer invalidate];
    }
}

- (void)updateSlider:(id)sender {
    self.audioPlayer.currentTime = self.seekBar.value;
    
    NSTimeInterval timePassed = self.audioPlayer.currentTime;
    int min= timePassed/60;
    int sec= lroundf(timePassed) % 60;
    NSTimeInterval totalTime = self.audioPlayer.duration;
    int min1= totalTime/60;
    int sec1= lroundf(totalTime-timePassed) % 60;
    
    // If seconds is under 10 put a zero before the second value
    NSString *secStr = [NSString stringWithFormat:@"%d", sec];
    if (secStr.length == 1) {
        secStr = [NSString stringWithFormat:@"0%d", sec];
    }
    
    NSString *secStr1 = [NSString stringWithFormat:@"%d", sec1];
    if (secStr1.length == 1) {
        secStr1 = [NSString stringWithFormat:@"0%d", sec1];
    }
    
    self.currentTime.text = [NSString stringWithFormat:@"%d:%@", min, secStr];
    self.endTime.text = [NSString stringWithFormat:@"-%d:%@", min1, secStr1];
}

- (void)playAudio:(id)sender {
    if (![self.audioPlayer isPlaying]) {
        self.playButton.hidden = YES;
        self.stopButton.hidden = NO;
        [self.audioPlayer play];
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
    }
}

- (void)stopAudio:(id)sender {
    self.stopAudio = FullStopAudioPause;
    if ([self.audioPlayer isPlaying]) {
        if (self.stopAudio != FullStopAudioReset && self.stopAudio != FullStopAudioPause) {
            //If enum hasn't been set default to StopAudioPause
            self.stopAudio = FullStopAudioPause;
            [self.audioPlayer pause];
        } else if (self.stopAudio == FullStopAudioReset) {
            [self.audioPlayer setCurrentTime:0.0];
            [self.audioPlayer stop];
        } else if (self.stopAudio == FullStopAudioPause) {
            [self.audioPlayer pause];
        }
        
        self.stopButton.hidden = YES;
        self.playButton.hidden = NO;
    }
}

- (void)startAudio:(id)sender {
    self.stopAudio = FullStopAudioPause;
    if (![self.audioPlayer isPlaying]) {
        [self.audioPlayer play];
        
        self.stopButton.hidden = NO;
        self.playButton.hidden = YES;
    }
}

- (void)nextTrack {
    if ([_delegate respondsToSelector:@selector(nextTrack)]) {
        [_delegate nextTrack];
    }
}


- (void)previousTrack {
    if ([_delegate respondsToSelector:@selector(previousTrack)]) {
        [_delegate previousTrack];
    }
}

- (void)dismissTour {
    if ([_delegate respondsToSelector:@selector(dismissTour)]) {
        [_delegate dismissTour];
    }
}

- (void)cleanUp {
    [self.audioPlayer stop];
}

- (void)setFileURL:(NSURL *)fileURL {
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    [_audioPlayer prepareToPlay];
}

-(UIImage *)thumbImageForColor:(UIColor *)color {
    CGSize imageSize = CGSizeMake(3, 15);
    UIColor *fillColor = color;
    UIGraphicsBeginImageContextWithOptions(imageSize, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [fillColor setFill];
    CGContextFillRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
