//
//  RECluster.m
//  REMarkerClusterer
//
//  Created by Roman Efimov on 3/9/11.
//  Copyright 2011 Roman Efimov. All rights reserved.
//

#import "RECluster.h"


@implementation RECluster

@synthesize markerClusterer, gridSize, coordinate, markers, averageCenter, hasCenter, title, bounds;

- (id)initWithClusterer:(REMarkerClusterer *)clusterer {
    /*markerClusterer = clusterer;
    gridSize = [clusterer getGridSize];
    averageCenter = [clusterer isAverageCenter];
    markers = [[NSMutableArray alloc] initWithCapacity:0];
    hasCenter = NO;
    
    return [super init]; */
    
    self = [super init];
    if (self) {
        self.markerClusterer = clusterer;
        self.gridSize = [clusterer getGridSize];
        self.averageCenter = [clusterer isAverageCenter];
        markers = [[NSMutableArray alloc] initWithCapacity:0];
        self.hasCenter = NO;
        bounds = [[RELatLngBounds alloc] initWithMapView:markerClusterer.mapView];
    }
    return self;
}

- (void)calculateBounds {
    [bounds setSouthWest:coordinate northEast:coordinate];
    [bounds setExtendedBounds:markerClusterer.gridSize];
    //RELatLngBounds *_bounds = [RELatLngBounds boundsWithSouthWest:coordinate northEast:coordinate mapView:markerClusterer.mapView];
    //self.bounds = [markerClusterer getExtendedBounds:_bounds];
    //[_bounds release];
}

- (bool)isMarkerInClusterBounds:(REMarker *)marker {
    return [bounds contains:marker.coordinate];
}

- (bool)isMarkerAlreadyAdded:(REMarker *)marker {
    for (int i=0; i < [markers count]; i++) {
        REMarker *m = (REMarker *)[markers objectAtIndex:i];
        if (m.ID == marker.ID)
            return YES;
    }
    return NO;
}

- (void)setAverageCenter {
    double x = 0;
    double y = 0;
    double z = 0;
    
    for (REMarker *marker in markers) {
        //REMarker *marker = [markers objectAtIndex:[markers count] - 1];
        
        double lat = marker.coordinate.latitude * M_PI/180;
        double lon = marker.coordinate.longitude * M_PI/180;
        //NSLog(@"lat = %f, lng = %f", marker.coordinate.latitude, marker.coordinate.longitude);
        
        x += cos(lat) * cos(lon);
        y += cos(lat) * sin(lon);
        z += sin(lat);
        
    }
   // NSLog(@"x = %f, y = %f, z = %f", x, y, z);
    double count = [markers count];
    
    x = x / count;
    y = y / count;
    z = z / count;
    
    double r = sqrt(x*x + y*y + z*z);
    double lat1 = asin(z/r) / (M_PI/180);
    double lon1 = atan2(y, x) / (M_PI/180);
    
    //NSLog(@"lat1 = %f, lng1 = %f", coordinate.latitude, coordinate.longitude);
    //NSLog(@"lat2 = %f, lng2 = %f", lat1, lon1);
    
    coordinate = CLLocationCoordinate2DMake(lat1, lon1);
    
    //double avgX = 
    
    /*double s1, c1;
    double s2, c2;
    for (REMarker *marker in markers) {
        s1 += sin(marker.coordinate.latitude);
        c1 += cos(marker.coordinate.latitude);
        
        s2 += sin(marker.coordinate.longitude);
        c2 += cos(marker.coordinate.longitude);
    }
    
    s1 = s1 / [markers count];
    c1 = c1 / [markers count];
    
    s2 = s2 / [markers count];
    c2 = c2 / [markers count];
    
    double o1 = atan(c1/s1);
    
    double o2 = atan(c2/s2);
    //avgLng = avgLng / [markers count];
    
    coordinate = CLLocationCoordinate2DMake(o1, o2);*/
}

- (bool)addMarker:(REMarker *)marker {
    if ([self isMarkerAlreadyAdded:marker]) {
        return NO;
    }
    
    if (!hasCenter) {
        coordinate = marker.coordinate;
        hasCenter = YES;
        [self calculateBounds];
    } else {
        if (averageCenter && [markers count] >= 10) {
            double l = [markers count] + 1;
            double lat = (coordinate.latitude * (l-1) + marker.coordinate.latitude) / l;
            double lng = (coordinate.longitude * (l-1) + marker.coordinate.longitude) / l;
            coordinate = CLLocationCoordinate2DMake(lat, lng);
            hasCenter = YES;
            [self calculateBounds];
        }
    }
    [markers addObject:marker];
    return YES;
}


@end
