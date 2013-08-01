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

@implementation RECluster

- (id)initWithClusterer:(REMarkerClusterer *)clusterer
{
    if ((self = [super init])) {
        _markerClusterer = clusterer;
        _averageCenter = [clusterer isAverageCenter];
        _markers = [[NSMutableArray alloc] init];
        _hasCenter = NO;
        _bounds = [[RELatLngBounds alloc] initWithMapView:_markerClusterer.mapView];
    }
    return self;
}

- (void)calculateBounds
{
    [_bounds setSouthWest:_coordinate northEast:_coordinate];
    [_bounds setExtendedBounds:_markerClusterer.gridSize];
}

- (BOOL)isMarkerInClusterBounds:(REMarker *)marker
{
    return [_bounds contains:marker.coordinate];
}

- (NSInteger)markersInClusterFromMarkers:(NSArray *) markers
{
    int result = 0;
    for (REMarker *marker in markers) {
        if ([self isMarkerAlreadyAdded:marker]) result++;
    }
    return result;
}

- (BOOL)isMarkerAlreadyAdded:(REMarker *)marker
{
    for (REMarker *m in _markers) {
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
    
    for (REMarker *marker in _markers) {
        double lat = marker.coordinate.latitude * M_PI /  180;
        double lon = marker.coordinate.longitude * M_PI / 180;

        x += cos(lat) * cos(lon);
        y += cos(lat) * sin(lon);
        z += sin(lat);
    }
    
    x = x / [_markers count];
    y = y / [_markers count];
    z = z / [_markers count];
    
    double r = sqrt(x * x + y * y + z * z);
    double lat1 = asin(z / r) / (M_PI / 180);
    double lon1 = atan2(y, x) / (M_PI / 180);
    
    _coordinate = CLLocationCoordinate2DMake(lat1, lon1);
}

- (BOOL)addMarker:(REMarker *)marker 
{
    if ([self isMarkerAlreadyAdded:marker])
        return NO;

    if (!_hasCenter) {
        _coordinate = marker.coordinate;
        _coordinateTag = [NSString stringWithFormat:@"%f%f",_coordinate.latitude,_coordinate.longitude];
        _hasCenter = YES;
        [self calculateBounds];
    } else {
        if (_averageCenter && [_markers count] >= 2) {
            double l = [_markers count] + 1;
            double lat = (_coordinate.latitude * (l - 1) + marker.coordinate.latitude) / l;
            double lng = (_coordinate.longitude * (l - 1) + marker.coordinate.longitude) / l;
            _coordinate = CLLocationCoordinate2DMake(lat, lng);
            _coordinateTag = [NSString stringWithFormat:@"%f%f",_coordinate.latitude,_coordinate.longitude];
            _hasCenter = YES;
            [self calculateBounds];
        }
    }
    [_markers addObject:marker];
    
    if (_markers.count == 1){
        self.title = ((REMarker *)[_markers lastObject]).title;
        self.subtitle = ((REMarker *)[_markers lastObject]).title;
    } else{
        self.title = [NSString stringWithFormat:self.markerClusterer.clusterTitle, _markers.count];
        self.subtitle = @"";
    }
    
    return YES;
}

- (void)printDescription
{
    NSLog(@"---- CLUSTER: %@ - %d ----",_coordinateTag, _markers.count);
    for (REMarker *marker in _markers) {
        NSLog(@"  MARKER: %@-%@", marker.title, marker.subtitle);
    }
}

@end
