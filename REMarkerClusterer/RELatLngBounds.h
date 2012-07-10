//
//  RELatLngBounds.h
//  REMarkerClusterer
//
//  Created by Roman Efimov on 3/9/11.
//  Copyright 2011 Roman Efimov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CLLocation.h>

@interface RELatLngBounds : NSObject {
    CLLocationCoordinate2D northEast;
    CLLocationCoordinate2D northWest;
    CLLocationCoordinate2D southWest;
    CLLocationCoordinate2D southEast;
    MKMapView *__weak _mapView;
}

@property (nonatomic, readwrite) CLLocationCoordinate2D northEast;
@property (nonatomic, readwrite) CLLocationCoordinate2D northWest;
@property (nonatomic, readwrite) CLLocationCoordinate2D southWest;
@property (nonatomic, readwrite) CLLocationCoordinate2D southEast;
@property (nonatomic, weak) MKMapView *_mapView;

- (id)initWithMapView:(MKMapView *)mapView;
- (void)setSouthWest:(CLLocationCoordinate2D)sw northEast:(CLLocationCoordinate2D)ne;
- (void)setExtendedBounds:(int)gridSize;
- (bool)contains:(CLLocationCoordinate2D)coordinate;

@end
