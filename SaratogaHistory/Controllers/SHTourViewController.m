//
//  SHTourViewController.m
//  Saratoga History
//
//  Created by Richard Liu on 6/21/15.
//  Copyright (c) 2015 Richard Liu. All rights reserved.
//

@import MapKit;

#import "SHTourViewController.h"
#import "CSRouteAnnotation.h"
#import "CSRouteView.h"
#import "CSMapAnnotation.h"
#import "CSImageAnnotationView.h"

#define MARGIN 25

@interface SHTourViewController () {
    NSArray *places;
    NSMutableArray *placeViewControllers;
    SHPlaceViewController *currentPlaceVC;
    NSMutableArray *annotations;
    NSMutableArray *coordinates;
    NSMutableDictionary* _routeViews;
}

@end

@implementation SHTourViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupMapView];
    _routeViews = [[NSMutableDictionary alloc] init];
    
    [self loadPlaceViewControllersWithCompletion:^(NSArray *placeVCs, NSArray *coords, NSError *error) {
        placeViewControllers = [placeVCs mutableCopy];
        [self setupPageView];
        
        coordinates = [[NSMutableArray alloc] init];
        for(int idx = 0; idx < coords.count; idx++)
        {
            // break the string down even further to latitude and longitude fields.
            NSString* currentPointString = [coords objectAtIndex:idx];
            NSArray* latLonArr = [currentPointString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
            
            CLLocationDegrees latitude  = [[latLonArr objectAtIndex:0] doubleValue];
            CLLocationDegrees longitude = [[latLonArr objectAtIndex:1] doubleValue];
            
            CLLocation* currentLocation = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
            [coordinates addObject:currentLocation];
            
            if(coordinates.count == coords.count) {
                
                // CREATE THE ANNOTATIONS AND ADD THEM TO THE MAP
                
                // first create the route annotation, so it does not draw on top of the other annotations.
                CSRouteAnnotation* routeAnnotation = [[CSRouteAnnotation alloc] initWithPoints: coordinates];
                [_mapView addAnnotation:routeAnnotation];
                
                
                // create the rest of the annotations
                CSMapAnnotation* annotation = nil;
                
                // create the start annotation and add it to the array
                annotation = [[CSMapAnnotation alloc] initWithCoordinate:[[coordinates objectAtIndex:0] coordinate]
                                                          annotationType:CSMapAnnotationTypeStart
                                                                   title:@"Start Point"];
                [_mapView addAnnotation:annotation];
                
                
                // create the end annotation and add it to the array
                annotation = [[CSMapAnnotation alloc] initWithCoordinate:[[coordinates objectAtIndex:coordinates.count - 1] coordinate]
                                                          annotationType:CSMapAnnotationTypeEnd
                                                                   title:@"End Point"];
                [_mapView addAnnotation:annotation];

            }
        }
        
        annotations = [[NSMutableArray alloc] init];
        annotations = [[self annotations] mutableCopy];
        [self.mapView addAnnotations:annotations];
        
#warning hacky lol
        int64_t delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            JPSThumbnailAnnotation *annotation = [annotations objectAtIndex:0];
            if(annotation.view) {
                [annotation selectAnnotationInMap:self.mapView];
            } else {
                int64_t delayInSeconds = 0.3;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [annotation selectAnnotationInMap:self.mapView];
                    
                });
            }
        });
    }];
    
   
    
    [self createTourAudioTrack];
}

- (void)createTourAudioTrack {
    self.audioPlayerView = [[SYFullAudioPlayerView alloc] initWithFrame:CGRectMake(MARGIN,MARGIN,self.view.frame.size.width - 2*MARGIN, 75) audioFileURL:[NSURL URLWithString: @"placeholder"] autoplay:NO textColor:NULL];
    self.audioPlayerView.delegate = self;
    self.audioPlayerView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.9];
    self.audioPlayerView.layer.cornerRadius = 10.f;
    self.audioPlayerView.layer.masksToBounds = YES;
    [self.view addSubview: self.audioPlayerView];
}

- (void)setupPageView {
    // Create page view controller
    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SHPageViewController"];
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    
    SHPlaceViewController *startingViewController = placeViewControllers[0];
    
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    self.pageViewController.view.frame = CGRectMake(0, self.view.frame.size.height + 10, self.view.frame.size.width, [[UIScreen mainScreen] bounds].size.height - 60);
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.pageViewController.view.frame = CGRectMake(0, self.view.frame.size.height/2, self.view.frame.size.width, [[UIScreen mainScreen] bounds].size.height - 60);
    } completion:nil];
    
    UISwipeGestureRecognizer *pageSwipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(shrinkCurrentPage:)];
    UISwipeGestureRecognizer *pageSwipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(expandCurrentPage:)];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expandCurrentPage:)];
    tapGesture.delegate = self;
    pageSwipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    pageSwipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.pageViewController.view addGestureRecognizer:pageSwipeDown];
    [self.pageViewController.view addGestureRecognizer:pageSwipeUp];
    [self.pageViewController.view addGestureRecognizer:tapGesture];
}

- (void)setupMapView {
    self.mapView.mapType = MKMapTypeHybrid;
    self.mapView.showsUserLocation = YES;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.mapView.delegate = self;
    float spanX = 0.0160;
    float spanY = 0.0160;
    MKCoordinateRegion region;
    region.center.latitude = 37.254017;// self.locationManager.location.coordinate.latitude;
    region.center.longitude = -122.033921;// self.locationManager.location.coordinate.longitude;
    region.span.latitudeDelta = spanX;
    region.span.longitudeDelta = spanY;
    [self.mapView setRegion:region animated:YES];
    
    MKMapPoint userPoint = MKMapPointForCoordinate(self.mapView.userLocation.location.coordinate);
    MKMapRect mapRect = self.mapView.visibleMapRect;
    BOOL inside = MKMapRectContainsPoint(mapRect, userPoint);
    if(inside) {
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
    }
    double zoom = log2(360 * ((self.mapView.frame.size.width/256) / self.mapView.region.span.longitudeDelta));
    NSLog(@"zoom: %f",zoom);
}

- (void)loadPlaceViewControllersWithCompletion:(void (^)(NSArray *placeVCs, NSArray* coords, NSError *error))completionBlock {
    [[SHPlaceManager sharedInstance] placesWithCompletion:^(NSArray *placesArray, NSError *error) {
        places = placesArray;
        NSMutableArray *placeVCs = [[NSMutableArray alloc] init];
        NSMutableArray *coords = [[NSMutableArray alloc] init];
        
        for(int i = 0; i < places.count; i++) {
            SHPlaceViewController *placeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SHPlaceViewController"];
            placeViewController.pageIndex = i;
            placeViewController.place = places[i];
            placeViewController.delegate = self;
            placeViewController.expanded = NO;
            placeViewController.showsAudioView = NO;
            
            SHPlace *place = places[i];
            [coords addObject: [NSString stringWithFormat: @"%f,%f", place.lat, place.lng]];
            NSLog(@"%@,", [coords objectAtIndex: i]);
            
            [placeVCs addObject:placeViewController];
            
            if(i == places.count - 1) {
                completionBlock(placeVCs, coords, nil);
            }
        }
    }];
}

- (NSArray *)annotations {
    for(SHPlace *place in places) {
        int index = place.index;
        
        place.annotationThumbnail.expandBlock = ^{
            [self flipToPage:index];
        };
        [annotations addObject:[JPSThumbnailAnnotation annotationWithThumbnail:place.annotationThumbnail]];
        if(annotations.count == places.count) {
            return annotations;
        }
    }
    return nil;
}

- (void)expandCurrentPage: (id)sender {
    currentPlaceVC.expanded = YES;
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.pageViewController.view.frame = CGRectMake(0, 110, self.view.frame.size.width, self.pageViewController.view.frame.size.height);
    } completion:nil];
}

-(void)tapExpandCurrentPage: (id)sender {
    currentPlaceVC.expanded = YES;
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.pageViewController.view.frame = CGRectMake(0, 110, self.view.frame.size.width, self.pageViewController.view.frame.size.height);
    } completion:nil];
    
    UIView *temp = (UIView *)[sender view];
    [temp removeGestureRecognizer: sender];
}

- (void)shrinkCurrentPage: (id)sender {
    currentPlaceVC.expanded = NO;
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.pageViewController.view.frame = CGRectMake(0, self.view.frame.size.height/2, self.view.frame.size.width, [[UIScreen mainScreen] bounds].size.height - 110);
    } completion:nil];
    //    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expandCurrentPage:)];
    //    tapGesture.delegate = self;
    //    UIView *temp = (UIView *)[sender view];
    //    [temp addGestureRecognizer: tapGesture];
}

- (void)flipToPage:(int)index {
    NSArray *viewControllers  = [NSArray arrayWithObjects:placeViewControllers[index], nil];
    
    if(index > [placeViewControllers indexOfObject:currentPlaceVC]) {
        [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
    } else {
        [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:NULL];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // Send the user to the Settings fo r this app
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:settingsURL];
    }
}

- (void)dismissTour {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((SHPlaceViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return placeViewControllers[index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((SHPlaceViewController*) viewController).pageIndex;
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [places count]) {
        return nil;
    }
    return placeViewControllers[index];
}

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed {
    
    if(completed) {
        //pause the old player
        [currentPlaceVC pause];
        JPSThumbnailAnnotation *prevAnnotation = [annotations objectAtIndex:currentPlaceVC.pageIndex];
        [prevAnnotation deselectAnnotationInMap:self.mapView];
        currentPlaceVC = [pageViewController.viewControllers lastObject];
        JPSThumbnailAnnotation *newAnnotation = [annotations objectAtIndex:currentPlaceVC.pageIndex];
        [newAnnotation selectAnnotationInMap:self.mapView];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView placeView:(SHPlaceViewController *)placeVC{
    if((scrollView.contentOffset.y < -30) && placeVC.expanded) {
        [self shrinkCurrentPage:self];
    } else if ((scrollView.contentOffset.y > 100) && !placeVC.expanded) {
        [self expandCurrentPage:self];
    }
}

-(void)enableUserInteraction{
    [self.view setUserInteractionEnabled:YES];
}

- (IBAction)resetMapRegion:(id)sender {
    float spanX = 0.0150;
    float spanY = 0.0150;
    MKCoordinateRegion region;
    region.center.latitude = 37.254017;// self.locationManager.location.coordinate.latitude;
    region.center.longitude = -122.033921;// self.locationManager.location.coordinate.longitude;
    region.span.latitudeDelta = spanX;
    region.span.longitudeDelta = spanY;
    [self.mapView setRegion:region animated:YES];
}

//#pragma mark mapView delegate functions
//- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
//{
//    // turn off the view of the route as the map is chaning regions. This prevents
//    // the line from being displayed at an incorrect positoin on the map during the
//    // transition.
//    for(NSObject* key in [_routeViews allKeys])
//    {
//        CSRouteView* routeView = [_routeViews objectForKey:key];
//        routeView.hidden = YES;
//    }
//    
//}
//- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
//{
//    // re-enable and re-poosition the route display.
//    for(NSObject* key in [_routeViews allKeys])
//    {
//        CSRouteView* routeView = [_routeViews objectForKey:key];
//        routeView.hidden = NO;
//        [routeView regionChanged];
//    }
//    
//}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view conformsToProtocol:@protocol(JPSThumbnailAnnotationViewProtocol)]) {
        [((NSObject<JPSThumbnailAnnotationViewProtocol> *)view) didSelectAnnotationViewInMap:mapView];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if ([view conformsToProtocol:@protocol(JPSThumbnailAnnotationViewProtocol)]) {
        [((NSObject<JPSThumbnailAnnotationViewProtocol> *)view) didDeselectAnnotationViewInMap:mapView];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKAnnotationView* annotationView = nil;
    if ([annotation conformsToProtocol:@protocol(JPSThumbnailAnnotationProtocol)]) {
        return [((NSObject<JPSThumbnailAnnotationProtocol> *)annotation) annotationViewInMap:mapView];
    }
    
    else if([annotation isKindOfClass:[CSRouteAnnotation class]])
    {
        
    CSRouteAnnotation* routeAnnotation = (CSRouteAnnotation*) annotation;
        
        annotationView = [_routeViews objectForKey:routeAnnotation.routeID];
        
        if(nil == annotationView)
        {
            CSRouteView* routeView = [[CSRouteView alloc] initWithFrame:CGRectMake(0, 0, _mapView.frame.size.width, _mapView.frame.size.height)];
            
            routeView.annotation = routeAnnotation;
            routeView.mapView = _mapView;
            
            [_routeViews setObject:routeView forKey:routeAnnotation.routeID];
            
            annotationView = routeView;
        }
    }

    return annotationView;;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    // turn off the view of the route as the map is chaning regions. This prevents
    // the line from being displayed at an incorrect positoin on the map during the
    // transition.
    for(NSObject* key in [_routeViews allKeys])
    {
        CSRouteView* routeView = [_routeViews objectForKey:key];
        routeView.hidden = YES;
    }
    
}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    // re-enable and re-poosition the route display.
    for(NSObject* key in [_routeViews allKeys])
    {
        CSRouteView* routeView = [_routeViews objectForKey:key];
        routeView.hidden = NO;
        [routeView regionChanged];
    }
    
}

@end
