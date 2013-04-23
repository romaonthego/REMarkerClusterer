//
//  DemoViewController.h
//  REMarkerClustererExample
//
//  Created by Roman Efimov on 7/9/12.
//  Copyright (c) 2012 Roman Efimov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "REMarkerClusterer.h"

@interface DemoViewController : UIViewController <MKMapViewDelegate>

@property (strong, readonly, nonatomic) MKMapView *mapView;
@property (strong, readonly, nonatomic) REMarkerClusterer *clusterer;

@end
