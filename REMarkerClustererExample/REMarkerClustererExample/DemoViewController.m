//
//  DemoViewController.m
//  REMarkerClustererExample
//
//  Created by Roman Efimov on 7/9/12.
//  Copyright (c) 2012 Roman Efimov. All rights reserved.
//

#import "DemoViewController.h"

@interface DemoViewController ()

@end

@implementation DemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Add map view
    //
	_mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_mapView];
    
    // Create clusterer, assign a map view and delegate (MKMapViewDelegate)
    //
    _clusterer = [[REMarkerClusterer alloc] initWithMapView:_mapView delegate:self];
    [_clusterer setLatitude:37.786996 longitude:-97.440100 delta:30.03863];
    
    // Set smaller grid size for an iPad
    //
    _clusterer.gridSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 25 : 20;    
    _clusterer.clusterTitle = @"%i items";
    
    // Populate with sample data
    //
    NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Points" ofType:@"plist"]];
    NSInteger index = 0;
    for (NSDictionary *dict in [data objectForKey:@"Points"]) {
        REMarker *marker = [[REMarker alloc] init];
        marker.markerId = [[dict objectForKey:@"id"] intValue];
        marker.coordinate = CLLocationCoordinate2DMake([[dict objectForKey:@"latitude"] floatValue], [[dict objectForKey:@"longitude"] floatValue]);
        marker.title = [NSString stringWithFormat:@"One item <id: %i>", index];
        marker.userInfo = @{@"index": @(index)};
        [_clusterer addMarker:marker];
        index++;
    }
    
    // Create clusters (without animations on view load)
    //
    [_clusterer clusterize:NO];
    
    // Zoom to show all clusters/markers on the map
    //
    [_clusterer zoomToAnnotationsBounds:_clusterer.markers];
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
        REMarker *marker = [cluster.markers objectAtIndex:0];
        message = [NSString stringWithFormat:@"%@", marker.userInfo];
    } else {
         message = [NSString stringWithFormat:@"Count: %i", cluster.markers.count];
    }   
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Test"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
    [alertView show];
}

@end
