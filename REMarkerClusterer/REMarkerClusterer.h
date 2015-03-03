//
// REMarkerClusterer.h
// REMarkerClusterer
//
// Copyright (c) 2011-2013 Roman Efimov (https://github.com/romaonthego)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <float.h>
#import "REMarker.h"
#import "RELatLngBounds.h"
#import "RECluster.h"

@protocol REMarkerClusterDelegate <MKMapViewDelegate>

@optional

- (void)markerClusterer:(REMarkerClusterer *)markerCluster withMapView:(MKMapView *)mapView updateViewOfAnnotation:(id<MKAnnotation>)annotation withView:(MKAnnotationView *)annotationView;

@end

@interface REMarkerClusterer : NSObject <MKMapViewDelegate> {
    NSMutableArray *_tempViews;
    BOOL _animated;
}

@property (weak, readwrite, nonatomic) MKMapView *mapView;
@property (strong, readonly, nonatomic) NSMutableArray *markers;
@property (strong, readonly, nonatomic) NSMutableArray *clusters;
@property (assign, readwrite, nonatomic) NSInteger gridSize;
@property (assign, readwrite, nonatomic) BOOL isAverageCenter;
@property (assign, readwrite, nonatomic) CGFloat maxDelayOfSplitAnimation;
@property (assign, readwrite, nonatomic) CGFloat maxDurationOfSplitAnimation;
@property (weak, readwrite, nonatomic) id<REMarkerClusterDelegate> delegate;
@property (copy, readwrite, nonatomic) NSString *clusterTitle;
@property (assign, readonly, nonatomic) BOOL animating;

- (id)initWithMapView:(MKMapView *)mapView delegate:(id <REMarkerClusterDelegate>)delegate;
- (void)addMarker:(id<REMarker>)marker;
- (void)addMarkers:(NSArray*)markers;
- (void)removeMarker:(id<REMarker>)marker;
- (void)removeAllMarkers;
- (void)zoomToAnnotationsBounds:(NSArray *)annotations;
- (void)clusterize:(BOOL)animated;
- (BOOL)isAnimating;

// Deprecated methods
//
- (void)clusterize __attribute__ ((deprecated)); // Use - (void)clusterize:(BOOL)animated;

@end
