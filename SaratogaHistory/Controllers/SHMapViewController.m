//
//  SHBaseViewController.m
//  Saratoga History
//
//  Created by Richard Liu on 12/19/14.
//  Copyright (c) 2015 Richard Liu. All rights reserved.
//

@import MapKit;

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)
#define IS_IPAD_PRO (IS_IPAD && SCREEN_MAX_LENGTH == 1366.0)

#import "SHMapViewController.h"
#import <JPSThumbnailAnnotation/JPSThumbnailAnnotation.h>
#import "SHTourViewController.h"

@interface SHMapViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIView *mainView;
@property (strong, nonatomic) IBOutlet UITableView *placesTableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *toggleListCardsButton;

@end

@implementation SHMapViewController {
    NSArray *places;
    NSMutableArray *placeViewControllers;
    SHPlaceViewController *currentPlaceVC;
    NSMutableArray *annotations;
    BOOL isShowingList;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor blackColor],
       NSFontAttributeName:[UIFont fontWithName:@"Avenir-Medium" size:20.0f]}];
    [self.navigationController.navigationBar setTintColor:[UIColor darkGrayColor]];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];

    if(IS_IPHONE_5 || IS_IPHONE_4_OR_LESS) {
        self.toggleListCardsButton.title = @"Cards";
    } else {
        self.toggleListCardsButton.title = @"Show Cards";
    }
    
    
    [self setupLocationManager];

    [self setupMapView];
    [self setupTableView];

    isShowingList = YES;
    
    [self loadPlaceViewControllersWithCompletion:^(NSArray *placeVCs, NSError *error) {
       placeViewControllers = [placeVCs mutableCopy];
        [self setupPageView];
        [self.placesTableView reloadData];
        
        annotations = [[NSMutableArray alloc] init];
        annotations = [[self annotations] mutableCopy];
        [self.mapView addAnnotations:annotations];
        
#warning hacky 
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadPlaceViewControllersWithCompletion:(void (^)(NSArray *placeVCs, NSError *error))completionBlock {
    [[SHPlaceManager sharedInstance] placesWithImageAnnotations:NO completion:^(NSArray *placesArray, NSError *error) {
        places = placesArray;
        NSMutableArray *placeVCs = [[NSMutableArray alloc] init];
        
        for(int i = 0; i < places.count; i++) {
            SHPlaceViewController *placeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SHPlaceViewController"];
            placeViewController.pageIndex = i;
            placeViewController.place = places[i];
            placeViewController.delegate = self;
            placeViewController.expanded = NO;
            placeViewController.isTourCard = NO;

            [placeVCs addObject:placeViewController];
            
            if(i == places.count - 1) {
                completionBlock(placeVCs, nil);
            }
        }
    }];
}

- (void)setupPageView {
    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SHPageViewController"];
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    
    SHPlaceViewController *startingViewController = placeViewControllers[0];
    currentPlaceVC = startingViewController;

    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    
    self.pageViewController.view.frame = CGRectMake(0, self.view.frame.size.height + 10, self.view.frame.size.width, [[UIScreen mainScreen] bounds].size.height - 60);

    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];

    [self hideCurrentPage:self];
    
    
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

- (void)setupTableView{
    self.placesTableView.delegate = self;
    self.placesTableView.dataSource = self;
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
        self.pageViewController.view.frame = CGRectMake(0, 75, self.view.frame.size.width, self.pageViewController.view.frame.size.height);
    } completion:nil];
}

-(void)tapExpandCurrentPage: (id)sender {
    currentPlaceVC.expanded = YES;
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.pageViewController.view.frame = CGRectMake(0, 75, self.view.frame.size.width, self.pageViewController.view.frame.size.height);
    } completion:nil];
    
    UIView *temp = (UIView *)[sender view];
    [temp removeGestureRecognizer: sender];
}

- (void)shrinkCurrentPage: (id)sender {
    currentPlaceVC.expanded = NO;
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.pageViewController.view.frame = CGRectMake(0, self.view.frame.size.height/2, self.view.frame.size.width, [[UIScreen mainScreen] bounds].size.height - 75);
    } completion:nil];
//    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expandCurrentPage:)];
//    tapGesture.delegate = self;
//    UIView *temp = (UIView *)[sender view];
//    [temp addGestureRecognizer: tapGesture];
}

- (void)hideCurrentPage: (id)sender {
   currentPlaceVC.expanded = NO;
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.pageViewController.view.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, [[UIScreen mainScreen] bounds].size.height - 75);
    } completion:nil];
}

- (void)flipToPage:(int)index {
    
    if(isShowingList){
        [self.placesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
                                    atScrollPosition:UITableViewScrollPositionTop animated:YES];
    } else {
        NSArray *viewControllers  = [NSArray arrayWithObjects:placeViewControllers[index], nil];
        
        if(index > [placeViewControllers indexOfObject:currentPlaceVC]) {
            [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
        } else {
            [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:NULL];
        }
    }
}

- (void)setupLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];

    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    // If the status is denied or only granted for when in use, display an alert
    if (status == kCLAuthorizationStatusDenied) {
        NSString *title = @"Location services are off";
        NSString *message = @"To use background location you must turn on 'Always' in the Location Services Settings";
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Settings", nil];
        [alertView show];
    }
    // The user has not enabled any location services. Request background authorization.
    else if (status == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // Send the user to the Settings for this app
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:settingsURL];
    }
}

#pragma mark - Table View

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"PlaceTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    SHPlace *place = [places objectAtIndex:indexPath.row];

    UIImageView *placeImageView = (UIImageView *)[cell viewWithTag:111];
    [placeImageView setImage:[UIImage imageWithContentsOfFile:place.images[0]]];
    
    UILabel *placeTitleLabel = (UILabel *)[cell viewWithTag:112];
    placeTitleLabel.text = place.placeTitle;
    
    UILabel *placeSubtitleLabel = (UILabel *)[cell viewWithTag:113];
    placeSubtitleLabel.text = place.descriptionText;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80.f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return places.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self shrinkCurrentPage:self];
    isShowingList = NO;

    [UIView animateWithDuration:0.5f animations:^{
        self.placesTableView.alpha = 0.f;
    } completion:^(BOOL finished) {
        [self flipToPage:indexPath.row];
    }];
    
    if(IS_IPHONE_5 || IS_IPHONE_4_OR_LESS) {
        self.toggleListCardsButton.title = @"List";
    } else {
        self.toggleListCardsButton.title = @"Show List";
    }
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

- (IBAction)toggleListCards:(id)sender {

    if(isShowingList == YES) {
        //show cards
        [self shrinkCurrentPage:self];
        [UIView animateWithDuration:0.5f animations:^{
            self.placesTableView.alpha = 0.f;
        }];
        
        if(IS_IPHONE_5 || IS_IPHONE_4_OR_LESS) {
            self.toggleListCardsButton.title = @"List";
        } else {
            self.toggleListCardsButton.title = @"Show List";
        }

        isShowingList = NO;
    } else {
        [self hideCurrentPage:self];

        [UIView animateWithDuration:0.5f animations:^{
            self.placesTableView.alpha = 1.f;
        }];
        
        if(IS_IPHONE_5 || IS_IPHONE_4_OR_LESS) {
            self.toggleListCardsButton.title = @"Cards";
        } else {
            self.toggleListCardsButton.title = @"Show Cards";
        }
        
        isShowingList = YES;
    }
}


- (IBAction)startTourTapped:(id)sender {
    [self performSegueWithIdentifier:@"ModalTourVC" sender:self];
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
    if ([annotation conformsToProtocol:@protocol(JPSThumbnailAnnotationProtocol)]) {
        return [((NSObject<JPSThumbnailAnnotationProtocol> *)annotation) annotationViewInMap:mapView];
    }
    return nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

@end
