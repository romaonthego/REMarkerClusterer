//
//  DemoViewController.m
//  REMarkerClustererExample
//
//  Created by Roman Efimov on 7/9/12.
//  Copyright (c) 2012 Roman Efimov. All rights reserved.
//

#import "DemoViewController.h"

@interface DemoViewController ()

@property (strong, readwrite, nonatomic) MKMapView *mapView;
@property (strong, readwrite, nonatomic) REMarkerClusterer *clusterer;

@end

@implementation DemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Add map view
    //
	self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.mapView setRegion:MKCoordinateRegionMake(CLLocationCoordinate2DMake(37.786996, -97.440100), MKCoordinateSpanMake(30.03863, 30.03863)) animated:YES];
    [self.view addSubview:self.mapView];
    
    // Create clusterer, assign a map view and delegate (MKMapViewDelegate)
    //
    self.clusterer = [[REMarkerClusterer alloc] initWithMapView:self.mapView delegate:self];
    
    // Set smaller grid size for an iPad
    //
    self.clusterer.gridSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 25 : 20;
    self.clusterer.clusterTitle = @"%i items";
    
    // Populate with sample data
    //
    NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Points" ofType:@"plist"]];
    
    [data[@"Points"] enumerateObjectsUsingBlock:^(NSDictionary *dictionary, NSUInteger idx, BOOL *stop) {
        REMarker *marker = [[REMarker alloc] init];
        marker.markerId = [dictionary[@"id"] integerValue];
        marker.coordinate = CLLocationCoordinate2DMake([dictionary[@"latitude"] floatValue], [dictionary[@"longitude"] floatValue]);
        marker.title = [NSString stringWithFormat:@"One item <id: %lu>", (unsigned long)idx];
        marker.userInfo = @{ @"index": @(idx) };
        [self.clusterer addMarker:marker];
    }];
    
    // Create clusters (without animations on view load)
    //
    [self.clusterer clusterize:NO];
    
    // Zoom to show all clusters/markers on the map
    //
    [self.clusterer zoomToAnnotationsBounds:self.clusterer.markers];
}

#pragma mark -
#pragma mark Rotation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark MKMapViewDeletate

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    RECluster *cluster = view.annotation;
    NSString *message;
    
    if (cluster.markers.count == 1) {
        REMarker *marker = (REMarker*)[cluster.markers objectAtIndex:0];
        message = [NSString stringWithFormat:@"%@", marker.userInfo];
    } else {
        message = [NSString stringWithFormat:@"Count: %lu", (unsigned long)cluster.markers.count];
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Test" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertView show];
}

@end
