//
//  SHPlace.m
//  Saratoga History
//
//  Created by Kabir Manghnani on 06/21/15.
//  Copyright (c) 2015 Kabir Manghnani. All rights reserved.
//

#import "SHPlace.h"
#import <Parse/Parse.h>

@implementation SHPlace

-(id)initWithIndex:(int)indx title:(NSString *)title lat:(float)latitude lng:(float)longitude address:(NSString *)addres descriptionText:(NSString *)text images:(NSArray *)imgs imageCaptions:(NSArray *)captions audio:(AVURLAsset *)audioAsset {
    self = [super init];
    if(self) {
       
        self.index = indx;
        self.placeTitle = title;
        self.lat = latitude;
        self.lng = longitude;
        self.address = addres;
        self.descriptionText = text;
        self.images = imgs;
        self.imageCaptions = captions;
        self.audioURLAsset = audioAsset;
        
        self.annotationThumbnail = [[JPSThumbnail alloc] init];
        UIColor *tintColor;
        if(self.index == 0 || self.index == 24) {
            tintColor = (self.index == 0) ? [UIColor greenColor] : [UIColor redColor];
        } else {
            tintColor = [UIColor colorWithWhite:0.5f alpha:0.8f];
        }
        self.annotationThumbnail.image = [self imageWithNumber:self.index + 1 tintedColor:tintColor size:CGSizeMake(80.f, 80.f)];
        self.annotationThumbnail.title = self.placeTitle;
        self.annotationThumbnail.subtitle = [self.imageCaptions firstObject];
        self.annotationThumbnail.coordinate = CLLocationCoordinate2DMake(self.lat, self.lng);
    }    
    return self;
}

- (UIImage *)imageWithNumber:(NSInteger)number
                    tintedColor:(UIColor *)tintColor
                           size:(CGSize)size
{
    UIView *coloredView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    coloredView.backgroundColor = tintColor;
    
    UILabel *numberLabel = [UILabel new];
    numberLabel.text = [NSString stringWithFormat:@"%li", (long)number];
    numberLabel.textColor = [UIColor whiteColor];
    
    CGFloat fontSize = size.width * 0.75;
    numberLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:fontSize];
    [numberLabel sizeToFit];
    [coloredView addSubview:numberLabel];
    
    numberLabel.center = coloredView.center;
    
    UIGraphicsBeginImageContextWithOptions(coloredView.bounds.size, NO, 0.0);
    
    [coloredView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

@end
