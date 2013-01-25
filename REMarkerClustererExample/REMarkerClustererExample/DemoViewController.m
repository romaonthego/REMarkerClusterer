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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        REMarkerClusterer *clusterer = [[REMarkerClusterer alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        clusterer.delegate = self;
        clusterer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [clusterer setLatitude:37.786996 longitude:-97.440100 delta:30.03863];
        
        // Set smaller grid size for an iPad
        clusterer.gridSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 25 : 20;
        [self.view addSubview:clusterer];
        
        clusterer.oneItemCaption = @"One item";
        clusterer.manyItemsCaption = @"%i items";
        
        NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Points" ofType:@"plist"]];
        for (NSDictionary *dict in [data objectForKey:@"Points"]) {
            REMarker *marker = [[REMarker alloc] init];
            marker.markerId = [[dict objectForKey:@"id"] intValue];
            marker.coordinate = CLLocationCoordinate2DMake([[dict objectForKey:@"latitude"] floatValue], 
                                                           [[dict objectForKey:@"longitude"] floatValue]);
            [clusterer addMarker:marker];
        }
        [clusterer zoomToAnnotationsBounds:clusterer.markers];
        [clusterer clusterize];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark REMarkerClustererDelegate functions

- (void)clusterCalloutAccessoryControlTapped:(NSArray *)items
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Test" 
                                                        message:[NSString stringWithFormat:@"Count: %i", [items count]] 
                                                       delegate:nil
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles: nil];
    [alertView show];
}

@end
