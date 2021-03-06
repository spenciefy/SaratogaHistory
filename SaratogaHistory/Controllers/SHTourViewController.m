//
//  SHTourViewController.m
//  Saratoga History
//
//  Created by Richard Liu on 6/21/15.
//  Copyright (c) 2015 Richard Liu. All rights reserved.
//

@import MapKit;

#import "SHTourViewController.h"

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)createTourAudioTrack {
    SHPlace *firstPlace = [places firstObject];

    self.audioPlayerView = [[SYFullAudioPlayerView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, 110) audioFileURL:firstPlace.audioURL autoplay:NO textColor:NULL];
    self.audioPlayerView.delegate = self;
    self.audioPlayerView.backgroundColor = [UIColor colorWithWhite:1.f alpha:1.f];
    self.audioPlayerView.placeLabel.text = firstPlace.placeTitle;
    
    UIBezierPath *maskPath;
    maskPath = [UIBezierPath bezierPathWithRoundedRect:self.audioPlayerView.bounds
                                     byRoundingCorners:(UIRectCornerBottomLeft|UIRectCornerBottomRight)
                                           cornerRadii:CGSizeMake(10.0, 10.0)];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.audioPlayerView.bounds;
    maskLayer.path = maskPath.CGPath;
    self.audioPlayerView.layer.mask = maskLayer;
    [self.view addSubview: self.audioPlayerView];
}

- (void)previousTrack {
    if(currentPlaceVC.pageIndex >= 1) {
        JPSThumbnailAnnotation *prevAnnotation = [annotations objectAtIndex:currentPlaceVC.pageIndex];
        [prevAnnotation deselectAnnotationInMap:self.mapView];
        prevAnnotation = nil;
        
        currentPlaceVC = [self.pageViewController.viewControllers lastObject];
        JPSThumbnailAnnotation *newAnnotation = [annotations objectAtIndex:currentPlaceVC.pageIndex - 1];
        [newAnnotation selectAnnotationInMap:self.mapView];

        
        SHPlace *newPlace = [places objectAtIndex:currentPlaceVC.pageIndex - 1];
        [self.audioPlayerView setFileURL:newPlace.audioURL];
        [self.audioPlayerView.placeLabel setText:newPlace.placeTitle];
        [self.audioPlayerView startAudio:self];
    }
}

- (void)nextTrack {
    if(currentPlaceVC.pageIndex <= 11) {
        JPSThumbnailAnnotation *prevAnnotation = [annotations objectAtIndex:currentPlaceVC.pageIndex];
        [prevAnnotation deselectAnnotationInMap:self.mapView];
        prevAnnotation = nil;

        currentPlaceVC = [self.pageViewController.viewControllers lastObject];
        JPSThumbnailAnnotation *newAnnotation = [annotations objectAtIndex:currentPlaceVC.pageIndex + 1];
        [newAnnotation selectAnnotationInMap:self.mapView];

        SHPlace *newPlace = [places objectAtIndex:currentPlaceVC.pageIndex + 1];
        [self.audioPlayerView setFileURL:newPlace.audioURL];
        [self.audioPlayerView.placeLabel setText:newPlace.placeTitle];
        [self.audioPlayerView startAudio:self];
    }
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
    [[SHPlaceManager sharedInstance] tourPlacesWithCompletion:^(NSArray *placesArray, NSError *error) {
        places = placesArray;
        NSMutableArray *placeVCs = [[NSMutableArray alloc] init];
        NSMutableArray *coords = [[NSMutableArray alloc] init];
        
        for(int i = 0; i < places.count; i++) {
            SHPlaceViewController *placeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SHPlaceViewController"];
            placeViewController.pageIndex = i;
            placeViewController.place = places[i];
            placeViewController.delegate = self;
            placeViewController.expanded = NO;
            placeViewController.isTourCard = YES;
            
            SHPlace *place = places[i];
            [coords addObject: [NSString stringWithFormat: @"%f,%f", place.lat, place.lng]];
            
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
        self.pageViewController.view.frame = CGRectMake(0, 125, self.view.frame.size.width, self.pageViewController.view.frame.size.height);
    } completion:nil];
}

-(void)tapExpandCurrentPage: (id)sender {
    currentPlaceVC.expanded = YES;
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.pageViewController.view.frame = CGRectMake(0, 125, self.view.frame.size.width, self.pageViewController.view.frame.size.height);
    } completion:nil];
    
    UIView *temp = (UIView *)[sender view];
    [temp removeGestureRecognizer: sender];
}

- (void)shrinkCurrentPage: (id)sender {
    currentPlaceVC.expanded = NO;
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.pageViewController.view.frame = CGRectMake(0, self.view.frame.size.height/2, self.view.frame.size.width, [[UIScreen mainScreen] bounds].size.height - 125);
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
    
    SHPlace *newPlace = [places objectAtIndex:index];
    [self.audioPlayerView setFileURL:newPlace.audioURL];
    [self.audioPlayerView.placeLabel setText:newPlace.placeTitle];
 //   [self.audioPlayerView startAudio:self];
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
    [self.audioPlayerView stopAudio:self];

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
        [self.audioPlayerView stopAudio:self];
        
        JPSThumbnailAnnotation *prevAnnotation = [annotations objectAtIndex:currentPlaceVC.pageIndex];
        [prevAnnotation deselectAnnotationInMap:self.mapView];
        prevAnnotation = nil;

        currentPlaceVC = [pageViewController.viewControllers lastObject];
        JPSThumbnailAnnotation *newAnnotation = [annotations objectAtIndex:currentPlaceVC.pageIndex];
        [newAnnotation selectAnnotationInMap:self.mapView];
        
        SHPlace *newPlace = [places objectAtIndex:currentPlaceVC.pageIndex];
        [self.audioPlayerView setFileURL:newPlace.audioURL];
        [self.audioPlayerView.placeLabel setText:newPlace.placeTitle];
     //   [self.audioPlayerView startAudio:self];
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
    
    return annotationView;;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

@end