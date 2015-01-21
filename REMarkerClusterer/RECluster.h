//
// RECluster.h
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
#import "RELatLngBounds.h"

@class REMarkerClusterer;
@protocol REMarker;

@interface RECluster : NSObject <MKAnnotation>

@property (strong, readwrite, nonatomic) RELatLngBounds *bounds;
@property (weak, readwrite, nonatomic) REMarkerClusterer *markerClusterer;
@property (assign, readwrite, nonatomic) CLLocationCoordinate2D coordinate;
@property (assign, readwrite, nonatomic) BOOL averageCenter;
@property (assign, readwrite, nonatomic) BOOL hasCenter;
@property (copy, readwrite, nonatomic) NSString *title;
@property (copy, readwrite, nonatomic) NSString *subtitle;
@property (strong, readwrite, nonatomic) NSMutableArray *markers;
@property (strong, readonly, nonatomic) NSString *coordinateTag;

- (id)initWithClusterer:(REMarkerClusterer *)clusterer;
- (BOOL)isMarkerAlreadyAdded:(id<REMarker>)marker;
- (NSInteger)markersInClusterFromMarkers:(NSArray *)markers;
- (BOOL)addMarker:(id<REMarker>)marker;
- (BOOL)isMarkerInClusterBounds:(id<REMarker>)marker;
- (void)setAverageCenter;
- (void)assignCoordinateForAnimation:(CLLocationCoordinate2D)coordinate;
- (void)printDescription;

@end
