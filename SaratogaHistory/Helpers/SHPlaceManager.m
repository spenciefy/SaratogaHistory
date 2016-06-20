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

- (void)placesWithImageAnnotations:(BOOL)showImageAnnotations completion:(void (^)(NSArray *placesArray, NSError *error))completionBlock {

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
        
        for (NSString *path in photoPathArray) {
            [images addObject:path];
        }
        
        SHPlace *place = [[SHPlace alloc]initWithIndex:index title:placeDictionary[@"Title"] lat:lat lng:lng address:placeDictionary[@"Address"] descriptionText:placeDictionary[@"Description"] images:images audio:nil imageAnnotation:showImageAnnotations];
        [places addObject:place];
        
        if(places.count == placesJSON.count) {
            NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]];
            NSArray *sortedArray = [places sortedArrayUsingDescriptors:sortDescriptors];
            
            completionBlock(sortedArray, nil);
        }
    }
}

- (void)tourPlacesWithCompletion:(void (^)(NSArray *placesArray, NSError *error))completionBlock {
    
    NSMutableArray *places = [[NSMutableArray alloc] init];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"TourSaratogaPlaces" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSArray *placesJSON = [json objectForKey:@"results"];
    
    for (NSDictionary *placeDictionary in placesJSON) {
        
        float lat = [placeDictionary[@"Latitude"] floatValue];
        float lng = [placeDictionary[@"Longitude"] floatValue];
        int index = [placeDictionary[@"Index"] intValue];
        
        NSString *directoryString = [NSString stringWithFormat:@"PlaceImages/%d", [self getIndexInPlaceImagesForTourIndex:index]];
        
        NSArray *photoPathArray = [[NSBundle mainBundle] pathsForResourcesOfType:@".JPG" inDirectory:directoryString];
        NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:photoPathArray.count];
        
        for (NSString *path in photoPathArray) {
            [images addObject:path];
        }
        
        NSString *audioPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"TourAudio/%d", index+1] ofType:@"m4a"];
        NSURL *audioURL = [NSURL fileURLWithPath:audioPath];
        
        SHPlace *place = [[SHPlace alloc]initWithIndex:index title:placeDictionary[@"Title"] lat:lat lng:lng address:placeDictionary[@"Address"] descriptionText:placeDictionary[@"Description"] images:images audio:audioURL imageAnnotation:YES];
        [places addObject:place];
        
        if(places.count == placesJSON.count) {
            NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]];
            NSArray *sortedArray = [places sortedArrayUsingDescriptors:sortDescriptors];
            
            completionBlock(sortedArray, nil);
        }
    }
}

-(int)getIndexInPlaceImagesForTourIndex:(int)index {
    switch (index) {
        case 0:
            return 19;
            break;
        case 1:
            return 17;
            break;
        case 2:
            return 16;
            break;
        case 3:
            return 27;
            break;
        case 4:
            return 28;
            break;
        case 5:
            return 29;
            break;
        case 6:
            return 14;
            break;
        case 7:
            return 12;
            break;
        case 8:
            return 10;
            break;
        case 9:
            return 30;
            break;
        case 10:
            return 5;
            break;
        case 11:
            return 4;
            break;
        case 12:
            return 22;
            break;
        default:
            return 0;
            break;
    }
}

@end
