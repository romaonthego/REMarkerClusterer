//
// RECluster.m
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

#import "RECluster.h"

@implementation RECluster

@synthesize markerClusterer, coordinate, markers, averageCenter, hasCenter, title, bounds;

- (id)initWithClusterer:(REMarkerClusterer *)clusterer
{
    if ((self = [super init])) {
        markerClusterer = clusterer;
        averageCenter = [clusterer isAverageCenter];
        markers = [[NSMutableArray alloc] initWithCapacity:0];
        hasCenter = NO;
        bounds = [[RELatLngBounds alloc] initWithMapView:markerClusterer.mapView];
    }
    return self;
}

- (void)calculateBounds
{
    [bounds setSouthWest:coordinate northEast:coordinate];
    [bounds setExtendedBounds:markerClusterer.gridSize];
}

- (BOOL)isMarkerInClusterBounds:(REMarker *)marker
{
    return [bounds contains:marker.coordinate];
}

- (BOOL)isMarkerAlreadyAdded:(REMarker *)marker
{
    for (REMarker *m in markers) {
        if ([m isEqual:marker])
            return YES;
    }
    return NO;
}

- (void)setAverageCenter
{
    double x = 0;
    double y = 0;
    double z = 0;
    
    for (REMarker *marker in markers) {
        double lat = marker.coordinate.latitude * M_PI /  180;
        double lon = marker.coordinate.longitude * M_PI / 180;

        x += cos(lat) * cos(lon);
        y += cos(lat) * sin(lon);
        z += sin(lat);
    }
    
    x = x / [markers count];
    y = y / [markers count];
    z = z / [markers count];
    
    double r = sqrt(x * x + y * y + z * z);
    double lat1 = asin(z / r) / (M_PI / 180);
    double lon1 = atan2(y, x) / (M_PI / 180);
    
    coordinate = CLLocationCoordinate2DMake(lat1, lon1);
}

- (BOOL)addMarker:(REMarker *)marker 
{
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
            double lat = (coordinate.latitude * (l - 1) + marker.coordinate.latitude) / l;
            double lng = (coordinate.longitude * (l - 1) + marker.coordinate.longitude) / l;
            coordinate = CLLocationCoordinate2DMake(lat, lng);
            hasCenter = YES;
            [self calculateBounds];
        }
    }
    [markers addObject:marker];
    return YES;
}


@end
