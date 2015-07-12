//
//  SHPlaceManager.m
//  Saratoga History
//
//  Created by Richard Liu on 12/26/14.
//  Copyright (c) 2014 Spencer Yen. All rights reserved.
//

#import "SHPlaceManager.h"
#import "Reachability.h"

@implementation SHPlaceManager

+ (SHPlaceManager *)sharedInstance {
    static SHPlaceManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[SHPlaceManager alloc] init];
        
    });
    return _sharedInstance;
}

- (void)placesWithCompletion:(void (^)(NSArray *placesArray, NSError *error))completionBlock {

    NSMutableArray *places = [[NSMutableArray alloc] init];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"SaratogaPlaces" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSArray *placesJSON = [json objectForKey:@"results"];
    
    for (NSDictionary *placeDictionary in placesJSON) {
        
        float lat = [placeDictionary[@"Latitude"] floatValue];
        float lng = [placeDictionary[@"Longitude"] floatValue];
        int index = [placeDictionary[@"Index"] intValue];
        
        NSString *directoryString = [NSString stringWithFormat:@"PlaceImages/%d", index + 1];
        
        NSArray *photoPathArray = [[NSBundle mainBundle] pathsForResourcesOfType:@".JPG" inDirectory:directoryString];
        NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:photoPathArray.count];
        NSMutableArray *captions = [[NSMutableArray alloc] initWithCapacity:photoPathArray.count];
        NSString *placeholderCaption = @"This is a long placeholder caption until we write out real captions for each of the images. We just need to see what long captions look like.";
        
        for (NSString *path in photoPathArray) {
            [images addObject:path];
            [captions addObject:placeholderCaption];
        }
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[[NSBundle mainBundle] URLForResource:placeDictionary[@"audioFileName"] withExtension:@"mp3"] options:nil];
        SHPlace *place = [[SHPlace alloc]initWithIndex:index title:placeDictionary[@"Title"] lat:lat lng:lng address:placeDictionary[@"Address"] descriptionText:placeDictionary[@"Description"] images:images imageCaptions:captions audio:asset];
        [places addObject:place];
        
        if(places.count == placesJSON.count) {
            NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]];
            NSArray *sortedArray = [places sortedArrayUsingDescriptors:sortDescriptors];
            
            completionBlock(sortedArray, nil);
        }
    }
}

@end
