//
//  RELatLngBounds.m
//  REMarkerClusterer
//
//  Created by Roman Efimov on 3/9/11.
//  Copyright 2011 Roman Efimov. All rights reserved.
//

#import "RELatLngBounds.h"


@implementation RELatLngBounds

@synthesize southEast, northEast, southWest, northWest, _mapView;

- (id)initWithMapView:(MKMapView *)mapView {
    self = [super init];
    if (self) {
        self._mapView = mapView;
    }
    return self;
}

- (void)setSouthWest:(CLLocationCoordinate2D)sw northEast:(CLLocationCoordinate2D)ne {
    self.southWest = sw;
    self.northEast = ne;
    
    self.southEast = CLLocationCoordinate2DMake(sw.latitude, ne.longitude);
    self.northWest = CLLocationCoordinate2DMake(ne.latitude, sw.longitude);
}

- (void)setExtendedBounds:(int)gridSize {
    CLLocationCoordinate2D tr = CLLocationCoordinate2DMake(self.northEast.latitude, self.northEast.longitude);
    CLLocationCoordinate2D bl = CLLocationCoordinate2DMake(self.southWest.latitude, self.southWest.longitude);
    
    CGPoint trPix = [self._mapView convertCoordinate:tr toPointToView:self._mapView];
    trPix.x += gridSize;
    trPix.y -= gridSize;
    
    CGPoint blPix = [self._mapView convertCoordinate:bl toPointToView:self._mapView];
    blPix.x -= gridSize;
    blPix.y += gridSize;
    
    CLLocationCoordinate2D ne = [self._mapView convertPoint:trPix toCoordinateFromView:self._mapView];
    CLLocationCoordinate2D sw = [self._mapView convertPoint:blPix toCoordinateFromView:self._mapView];
    self.northEast = ne;
    self.southWest = sw;
    
    self.southEast = CLLocationCoordinate2DMake(sw.latitude, ne.longitude);
    self.northWest = CLLocationCoordinate2DMake(ne.latitude, sw.longitude);
}

- (bool)contains:(CLLocationCoordinate2D)coordinate {
    CGPoint point = [_mapView convertCoordinate:coordinate toPointToView:_mapView];
    
    CGPoint topLeft = [_mapView convertCoordinate:northWest toPointToView:_mapView];
    CGPoint bottomRight = [_mapView convertCoordinate:southEast toPointToView:_mapView];
    CGPoint topRight = [_mapView convertCoordinate:northEast toPointToView:_mapView];

    if (point.x >= topLeft.x && point.x <= topRight.x) {
        if (point.y >= topLeft.y && point.y <= bottomRight.y)
            return YES;
    }
    return NO;
}


@end
