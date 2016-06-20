//
//  SHPlace.m
//  Saratoga History
//
//  Created by Kabir Manghnani on 06/21/15.
//  Copyright (c) 2015 Kabir Manghnani. All rights reserved.
//

#import "SHPlace.h"

@implementation SHPlace

-(id)initWithIndex:(int)indx title:(NSString *)title lat:(float)latitude lng:(float)longitude address:(NSString *)addres descriptionText:(NSString *)text images:(NSArray *)imgs audio:(NSURL *)audioURL imageAnnotation:(BOOL)isImageAnnotation {
    self = [super init];
    if(self) {
       
        self.index = indx;
        self.placeTitle = title;
        self.lat = latitude;
        self.lng = longitude;
        self.address = addres;
        self.descriptionText = text;
        self.images = imgs;
        self.audioURL = audioURL;
        
        self.annotationThumbnail = [[JPSThumbnail alloc] init];
        self.annotationThumbnail.title = self.placeTitle;
        self.annotationThumbnail.subtitle = self.descriptionText;
        self.annotationThumbnail.coordinate = CLLocationCoordinate2DMake(self.lat, self.lng);
        NSString *firstImageString = [self.images firstObject];
        UIImage *firstImage = [UIImage imageNamed:firstImageString];
        if(!isImageAnnotation) {
            self.annotationThumbnail.image = firstImage;
        } else {
            if(firstImage) {
                self.annotationThumbnail.image = [self overlayNumber:self.index+1 tintedColor:[UIColor colorWithWhite:0.7 alpha:0.5f] onImage:firstImage  size:CGSizeMake(80.f, 80.f)];
            } else {
                self.annotationThumbnail.image = firstImage;
            }
        }
    }
    return self;
}

- (UIImage *)overlayNumber:(NSInteger)number
            tintedColor:(UIColor *)tintColor
                      onImage:(UIImage *)backgroundImage
                      size:(CGSize)size
{
    UIView *coloredView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    coloredView.backgroundColor = tintColor;
    coloredView.alpha = 1.f;
    
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
    UIImage *numberImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return [self overlayImage:numberImage onImage:backgroundImage atPoint:CGPointMake(0.f, 0.f)];
}

- (UIImage *)overlayImage:(UIImage *)foregroundImage onImage:(UIImage *)backgroundImage atPoint:(CGPoint)point
{
    NSParameterAssert(foregroundImage);
    NSParameterAssert(backgroundImage);
    
    UIGraphicsBeginImageContextWithOptions(foregroundImage.size, NO, 0.0);
    [backgroundImage drawInRect:CGRectMake(0, 0, foregroundImage.size.width, foregroundImage.size.height)];
    [foregroundImage drawInRect:CGRectMake(point.x, point.y, foregroundImage.size.width, foregroundImage.size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
