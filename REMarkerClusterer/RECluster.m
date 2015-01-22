//
// RECluster.m
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

#import "RECluster.h"
#import "REMarkerClusterer.h"

@interface RECluster ()

@property (strong, readwrite, nonatomic) NSString *coordinateTag;

@end

@implementation RECluster

- (id)initWithClusterer:(REMarkerClusterer *)clusterer
{
    if ((self = [super init])) {
        self.markerClusterer = clusterer;
        self.averageCenter = [clusterer isAverageCenter];
        self.markers = [[NSMutableArray alloc] init];
        self.hasCenter = NO;
        self.bounds = [[RELatLngBounds alloc] initWithMapView:self.markerClusterer.mapView];
    }
    return self;
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate
{
    _coordinate = coordinate;

    // To support dragging of individual (non-cluster) pins, we pass the new
    // coordinate through to the underlying REMarker if we are not in the
    // midst of animating pins.
    if (![self.markerClusterer isAnimating] && (self.markers.count == 1)) {
        REMarker *marker = self.markers.lastObject;
        marker.coordinate = coordinate;
    }
}

- (void)calculateBounds
{
    [self.bounds setSouthWest:self.coordinate northEast:self.coordinate];
    [self.bounds setExtendedBounds:self.markerClusterer.gridSize];
}

- (BOOL)isMarkerInClusterBounds:(id<REMarker>)marker
{
    return [self.bounds contains:marker.coordinate];
}

- (NSInteger)markersInClusterFromMarkers:(NSArray *) markers
{
    NSInteger result = 0;
    for (id<REMarker>marker in markers) {
        if ([self isMarkerAlreadyAdded:marker])
            result++;
    }
    return result;
}

- (BOOL)isMarkerAlreadyAdded:(id<REMarker>)marker
{
    for (id<REMarker>m in self.markers) {
        if ([m isEqual:marker])
            return YES;
    }
    return NO;
}

- (void)setAverageCenter
{
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat z = 0;
    
    for (id<REMarker>marker in self.markers) {
        CGFloat lat = marker.coordinate.latitude * M_PI /  180;
        CGFloat lon = marker.coordinate.longitude * M_PI / 180;
        
        x += cos(lat) * cos(lon);
        y += cos(lat) * sin(lon);
        z += sin(lat);
    }
    
    x = x / self.markers.count;
    y = y / self.markers.count;
    z = z / self.markers.count;
    
    CGFloat r = sqrt(x * x + y * y + z * z);
    CGFloat lat1 = asin(z / r) / (M_PI / 180);
    CGFloat lon1 = atan2(y, x) / (M_PI / 180);
    
    self.coordinate = CLLocationCoordinate2DMake(lat1, lon1);
}

- (BOOL)addMarker:(id<REMarker>)marker
{
    if ([self isMarkerAlreadyAdded:marker])
        return NO;
    
    if (!self.hasCenter) {
        self.coordinate = marker.coordinate;
        self.coordinateTag = [NSString stringWithFormat:@"%f%f", self.coordinate.latitude, self.coordinate.longitude];
        self.hasCenter = YES;
        [self calculateBounds];
    } else {
        if (self.averageCenter && self.markers.count >= 2) {
            CGFloat l = self.markers.count + 1;
            CGFloat lat = (self.coordinate.latitude * (l - 1) + marker.coordinate.latitude) / l;
            CGFloat lng = (self.coordinate.longitude * (l - 1) + marker.coordinate.longitude) / l;
            self.coordinate = CLLocationCoordinate2DMake(lat, lng);
            self.coordinateTag = [NSString stringWithFormat:@"%f%f", self.coordinate.latitude, self.coordinate.longitude];
            self.hasCenter = YES;
            [self calculateBounds];
        }
    }
    [self.markers addObject:marker];
    
    if (self.markers.count == 1){
        self.title = ((id<REMarker>)self.markers.lastObject).title;
        self.subtitle = ((id<REMarker>)self.markers.lastObject).subtitle;
    } else{
        self.title = [NSString stringWithFormat:self.markerClusterer.clusterTitle, self.markers.count];
        self.subtitle = @"";
    }
    
    return YES;
}

- (void)printDescription
{
    NSLog(@"---- CLUSTER: %@ - %lu ----", self.coordinateTag, (unsigned long)self.markers.count);
    for (id<REMarker>marker in self.markers) {
        NSLog(@"  MARKER: %@-%@", marker.title, marker.subtitle);
    }
}

@end
