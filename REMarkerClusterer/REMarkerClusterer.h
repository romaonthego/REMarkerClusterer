//
// REMarkerClusterer.h
// REMarkerClusterer
//
// Copyright (c) 2011-2012 Roman Efimov (http://github.com/romaonthego)
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
#import "REMarker.h"
#import "RELatLngBounds.h"

@class RECluster;

@protocol REMarkerClustererDelegate;

@interface REMarkerClusterer : UIView <MKMapViewDelegate> {
    NSMutableArray *_tempViews;
    NSTimer *_tempTimer;
    BOOL _isRedrawing;
    BOOL _needsToRedraw;
}

@property (nonatomic) MKMapView *mapView;
@property (readwrite, copy) NSMutableArray *markers;
@property (readwrite, copy) NSMutableArray *clusters;
@property (nonatomic, readwrite) NSInteger gridSize;
@property (nonatomic, readwrite) BOOL isAverageCenter;
@property (nonatomic, assign) id<REMarkerClustererDelegate> delegate;
@property (nonatomic, copy) NSString *oneItemCaption;
@property (nonatomic, copy) NSString *manyItemsCaption;

- (void)addMarker:(REMarker *)marker;
- (void)setLatitude:(double)latitude longitude:(double)longitude delta:(double)delta;
- (void)zoomToAnnotationsBounds:(NSArray *)annotations;
- (void)clusterize;

@end

@protocol REMarkerClustererDelegate <NSObject>

@optional
- (void)clusterCalloutAccessoryControlTapped:(NSArray *)items;

@end
