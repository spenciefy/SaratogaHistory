//
//  SHTourViewController.h
//  Saratoga History
//
//  Created by Richard Liu on 6/21/15.
//  Copyright (c) 2015 Richard Liu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SHPlaceViewController.h"
#import "SHPlace.h"
#import <MapKit/MapKit.h>
#import "SHPlaceManager.h"
#import "SYFullAudioPlayerView.h"

@interface SHTourViewController : UIViewController <MKMapViewDelegate,UIPageViewControllerDataSource,UIPageViewControllerDelegate,CLLocationManagerDelegate, UIGestureRecognizerDelegate, SHPlaceViewControllerDelegate, SYFullAudioPlayerViewDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) UIPageViewController *pageViewController;

@property (strong, nonatomic) SYFullAudioPlayerView *audioPlayerView;

@property (nonatomic, retain) MKPolyline *routeLine;
@property (nonatomic, retain) MKPolylineView *routeLineView;

@end