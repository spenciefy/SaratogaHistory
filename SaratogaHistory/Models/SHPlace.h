//
//  SHPlace.h
//  Saratoga History
//
//  Created by Kabir Manghnani on 06/21/15.
//  Copyright (c) 2015 Kabir Manghnani. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JPSThumbnailAnnotation.h>
#import <AVFoundation/AVFoundation.h>

@interface SHPlace : NSObject

@property (nonatomic, assign) int index;
@property (nonatomic, strong) NSString *placeTitle;
@property (nonatomic, assign) float lat;
@property (nonatomic, assign) float lng;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *descriptionText;
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) JPSThumbnail *annotationThumbnail;
@property (nonatomic, strong) AVURLAsset *audioURLAsset;

-(id)initWithIndex:(int)indx title:(NSString *)title lat:(float)latitude lng:(float)longitude address:(NSString *)addres descriptionText:(NSString *)text images:(NSArray *)imgs audio:(AVURLAsset *)audioAsset imageAnnotation:(BOOL)isImageAnnotation;


@end

