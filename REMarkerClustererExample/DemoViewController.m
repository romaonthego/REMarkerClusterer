//
//  DemoViewController.m
//  REMarkerClustererExample
//
//  Created by Roman Efimov on 7/9/12.
//  Copyright (c) 2012 Roman Efimov. All rights reserved.
//

#import "DemoViewController.h"
#import "REMarkerClusterer.h"

@interface DemoViewController ()

@end

@implementation DemoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        REMarkerClusterer *clusterer = [[REMarkerClusterer alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
        clusterer.delegate = self;
        [clusterer setLatitude:37.786996 longitude:-97.440100 delta:30.03863];
        [self.view addSubview:clusterer];
        
        NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Points" ofType:@"plist"]];
        
        for (NSDictionary *dict in [data objectForKey:@"Points"]) {
            REMarker *marker = [[REMarker alloc] init];
            marker.ID = [[dict objectForKey:@"id"] intValue];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
