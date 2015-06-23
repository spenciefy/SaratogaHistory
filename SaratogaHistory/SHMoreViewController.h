//
//  SHMoreViewController.h
//  SaratogaHistory
//
//  Created by Richard Liu on 6/23/15.
//  Copyright (c) 2015 Richard Liu. All rights reserved.
//

#import "UIKit/UIKit.h"
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface SHMoreViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end
