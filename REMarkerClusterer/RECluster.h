//
//  RECluster.h
//  REMarkerClusterer
//
//  Created by Roman Efimov on 3/9/11.
//  Copyright 2011 Roman Efimov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "REMarkerClusterer.h"
#import <CoreLocation/CLLocation.h>
#import "RELatLngBounds.h"

@interface RECluster : NSObject <MKAnnotation> {
    REMarkerClusterer *__weak markerClusterer;
    NSString *title;
    int gridSize;
    CLLocationCoordinate2D coordinate;
    bool averageCenter;
    NSMutableArray *markers;
    bool hasCenter;
    RELatLngBounds *bounds;
}

@property (nonatomic) RELatLngBounds *bounds;
@property (nonatomic, weak) REMarkerClusterer *markerClusterer;
@property (nonatomic, readwrite) int gridSize;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, readwrite) bool averageCenter;
@property (nonatomic, readwrite) bool hasCenter;
@property (nonatomic) NSMutableArray *markers;
@property (nonatomic, copy) NSString *title;

- (bool)isMarkerAlreadyAdded:(REMarker *)marker;
- (bool)addMarker:(REMarker *)marker;
- (id)initWithClusterer:(REMarkerClusterer *)clusterer;
- (bool)isMarkerInClusterBounds:(REMarker *)marker;
- (void)setAverageCenter;

@end
