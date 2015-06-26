//
//  SHBaseViewController.h
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

@interface SHBaseViewController : UIViewController <MKMapViewDelegate,UIPageViewControllerDataSource,UIPageViewControllerDelegate,CLLocationManagerDelegate, UIGestureRecognizerDelegate, SHPlaceViewControllerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

- (IBAction)resetMapRegion:(id)sender;
- (IBAction)segmentedControlAction:(id)sender;

@end
