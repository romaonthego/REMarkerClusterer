//
//  REMarkerClusterer.h
//  REMarkerClusterer
//
//  Created by Roman Efimov on 3/8/11.
//  Copyright 2011 Roman Efimov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import <MapKit/MapKit.h>
#import <MapKit/MKAnnotation.h>
#import "REMarker.h"
#import "RELatLngBounds.h"

@class RECluster;

@interface REMarkerClusterer : UIView <MKMapViewDelegate> {
    NSMutableArray *markers;
    NSMutableArray *clusters;
    MKMapView *mapView;
    NSInteger gridSize;
    
    BOOL isRedrawing;
    BOOL needsToRedraw;
    NSMutableArray *tempViews;
    NSTimer *tempTimer;
    id __unsafe_unretained delegate;
}

@property (nonatomic) MKMapView *mapView;
@property (readwrite, copy) NSMutableArray *markers;
@property (readwrite, copy) NSMutableArray *clusters;
@property (nonatomic, readwrite) NSInteger gridSize;

@property (nonatomic, readwrite) BOOL isRedrawing;
@property (nonatomic, readwrite) BOOL needsToRedraw;

@property (nonatomic, unsafe_unretained) id delegate;

- (void)clusterize;
- (void)addMarker:(REMarker *)marker;
- (int)getGridSize;
- (bool)isAverageCenter;
- (void)setLatitude:(double)latitude longitude:(double)longitude delta:(double)delta;
- (void)setMapRegionForMinLat:(double)minLatitude minLong:(double)minLongitude maxLat:(double)maxLatitude maxLong:(double)maxLongitude;
- (void)zoomToAnnotationsBounds:(NSArray *)annotations;
- (CGPoint)findClosestAnnotationX:(double)x y:(double)y;
- (CGPoint)findClosestAnnotationX:(double)x y:(double)y views:(NSArray *)views;

@end
