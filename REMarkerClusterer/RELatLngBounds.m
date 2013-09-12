//
// RELatLngBounds.m
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

#import "RELatLngBounds.h"

@implementation RELatLngBounds

- (id)initWithMapView:(MKMapView *)mapView
{
    if ((self = [super init])) {
        _mapView = mapView;
    }
    return self;
}

- (void)setSouthWest:(CLLocationCoordinate2D)sw northEast:(CLLocationCoordinate2D)ne
{
    _southWest = sw;
    _northEast = ne;
    _southEast = CLLocationCoordinate2DMake(sw.latitude, ne.longitude);
    _northWest = CLLocationCoordinate2DMake(ne.latitude, sw.longitude);
}

- (void)setExtendedBounds:(NSInteger)gridSize
{
    CLLocationCoordinate2D tr = CLLocationCoordinate2DMake(_northEast.latitude, _northEast.longitude);
    CLLocationCoordinate2D bl = CLLocationCoordinate2DMake(_southWest.latitude, _southWest.longitude);
    
    CGPoint trPix = [_mapView convertCoordinate:tr toPointToView:_mapView];
    trPix.x += gridSize;
    trPix.y -= gridSize;
    
    CGPoint blPix = [_mapView convertCoordinate:bl toPointToView:_mapView];
    blPix.x -= gridSize;
    blPix.y += gridSize;
    
    CLLocationCoordinate2D ne = [_mapView convertPoint:trPix toCoordinateFromView:_mapView];
    CLLocationCoordinate2D sw = [_mapView convertPoint:blPix toCoordinateFromView:_mapView];
    
    _northEast = ne;
    _southWest = sw;
    _southEast = CLLocationCoordinate2DMake(sw.latitude, ne.longitude);
    _northWest = CLLocationCoordinate2DMake(ne.latitude, sw.longitude);
}

- (bool)contains:(CLLocationCoordinate2D)coordinate
{
    CGPoint point = [_mapView convertCoordinate:coordinate toPointToView:_mapView];
    CGPoint topLeft = [_mapView convertCoordinate:_northWest toPointToView:_mapView];
    CGPoint bottomRight = [_mapView convertCoordinate:_southEast toPointToView:_mapView];
    CGPoint topRight = [_mapView convertCoordinate:_northEast toPointToView:_mapView];

    if (point.x >= topLeft.x && point.x <= topRight.x)
        if (point.y >= topLeft.y && point.y <= bottomRight.y)
            return YES;
    
    return NO;
}

@end
