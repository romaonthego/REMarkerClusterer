//
// REMarkerClusterer.m
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

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "REMarkerClusterer.h"
#import "RECluster.h"

@interface REMarkerClusterer ()

@property (assign, readwrite, nonatomic) BOOL isRedrawing;

@end

@implementation REMarkerClusterer

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    
    _gridSize = 25;
    _tempViews = [[NSMutableArray alloc] init];
    _markers = [[NSMutableArray alloc] init];
    _clusters = [[NSMutableArray alloc] init];
    
    _clusterTitle = @"%i items";
    
    return self;
}

- (id)initWithMapView:(MKMapView *)mapView delegate:(id <MKMapViewDelegate>)delegate
{
    self = [self init];
    if (!self)
        return nil;
    
    self.mapView = mapView;
    self.delegate = delegate;
    
    return self;
}

- (void)setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    _mapView.delegate = self;
}

- (void)addMarker:(REMarker *)marker
{
    [_markers addObject:marker];
}

- (BOOL)markerInBounds:(REMarker *)marker
{
    CGPoint pix = [self.mapView convertCoordinate:marker.coordinate toPointToView:nil];
    if (pix.x >=-150 && pix.x <= _mapView.frame.size.width+150) {
        if (pix.y >=-150 && pix.y <= _mapView.frame.size.height+150) {
            return YES;
        }
    }
    return NO;
}

- (void)zoomToAnnotationsBounds:(NSArray *)annotations
{
    CLLocationDegrees minLatitude = DBL_MAX;
    CLLocationDegrees maxLatitude = -DBL_MAX;
    CLLocationDegrees minLongitude = DBL_MAX;
    CLLocationDegrees maxLongitude = -DBL_MAX;
    
    for (REMarker *annotation in annotations) {
        double annotationLat = annotation.coordinate.latitude;
        double annotationLong = annotation.coordinate.longitude;
        if (annotationLat == 0 && annotationLong == 0) continue;
        minLatitude = fmin(annotationLat, minLatitude);
        maxLatitude = fmax(annotationLat, maxLatitude);
        minLongitude = fmin(annotationLong, minLongitude);
        maxLongitude = fmax(annotationLong, maxLongitude);
    }
    
    // See function below
    [self setMapRegionForMinLat:minLatitude minLong:minLongitude maxLat:maxLatitude maxLong:maxLongitude];
    
    // If your markers were 40 in height and 20 in width, this would zoom the map to fit them perfectly. Note that there is a bug in mkmapview's set region which means it will snap the map to the nearest whole zoom level, so you will rarely get a perfect fit. But this will ensure a minimum padding.
    UIEdgeInsets mapPadding = UIEdgeInsetsMake(40.0, 10.0, 40.0, 10.0);
    CLLocationCoordinate2D relativeFromCoord = [self.mapView convertPoint:CGPointMake(0, 0) toCoordinateFromView:self.mapView];
    
    // Calculate the additional lat/long required at the current zoom level to add the padding
    CLLocationCoordinate2D topCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.top) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D rightCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.right) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D bottomCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.bottom) toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D leftCoord = [self.mapView convertPoint:CGPointMake(0, mapPadding.left) toCoordinateFromView:self.mapView];
    
    double latitudeSpanToBeAddedToTop = relativeFromCoord.latitude - topCoord.latitude;
    double longitudeSpanToBeAddedToRight = relativeFromCoord.latitude - rightCoord.latitude;
    double latitudeSpanToBeAddedToBottom = relativeFromCoord.latitude - bottomCoord.latitude;
    double longitudeSpanToBeAddedToLeft = relativeFromCoord.latitude - leftCoord.latitude;
    
    maxLatitude = maxLatitude + latitudeSpanToBeAddedToTop;
    minLatitude = minLatitude - latitudeSpanToBeAddedToBottom;
    
    maxLongitude = maxLongitude + longitudeSpanToBeAddedToRight;
    minLongitude = minLongitude - longitudeSpanToBeAddedToLeft;
    
    [self setMapRegionForMinLat:minLatitude minLong:minLongitude maxLat:maxLatitude maxLong:maxLongitude];
}

- (void) setMapRegionForMinLat:(double)minLatitude minLong:(double)minLongitude maxLat:(double)maxLatitude maxLong:(double)maxLongitude
{    
    MKCoordinateRegion region;
    region.center.latitude = (minLatitude + maxLatitude) / 2;
    region.center.longitude = (minLongitude + maxLongitude) / 2;
    region.span.latitudeDelta = (maxLatitude - minLatitude);
    region.span.longitudeDelta = (maxLongitude - minLongitude);
    
    if (region.span.latitudeDelta < 0.059863)
        region.span.latitudeDelta = 0.059863;
    
    if (region.span.longitudeDelta < 0.059863)
        region.span.longitudeDelta = 0.059863;
    
    // MKMapView BUG: this snaps to the nearest whole zoom level, which is wrong- it doesn't respect the exact region you asked for. See http://stackoverflow.com/questions/1383296/why-mkmapview-region-is-different-than-requested
    [self.mapView setRegion:region animated:YES];
}


- (void)setLatitude:(double)latitude longitude:(double)longitude delta:(double)delta
{
    MKCoordinateRegion newRegion;
    newRegion.center.latitude = latitude;
    newRegion.center.longitude = longitude;
    newRegion.span.latitudeDelta = delta;
    newRegion.span.longitudeDelta = delta;
    [self.mapView setRegion:newRegion animated:YES];
}

- (double)distanceBetweenPoints:(CLLocationCoordinate2D)p1 p2:(CLLocationCoordinate2D)p2
{
	double R = 6371; // Radius of the Earth in km
	double dLat = (p2.latitude - p1.latitude) * M_PI / 180;
	double dLon = (p2.longitude - p1.longitude) * M_PI / 180;
	double a = sin(dLat / 2) * sin(dLat / 2) + cos(p1.latitude * M_PI / 180) * cos(p2.latitude * M_PI / 180) * sin(dLon / 2) * sin(dLon / 2);
	double c = 2 * atan2(sqrt(a), sqrt(1 - a));
	double d = R * c;
	return d;
}

- (void)addToClosestCluster:(REMarker *)marker
{
    double distance = 40000; // Some large number
    RECluster *clusterToAddTo = nil;
    for (RECluster *cluster in _clusters) {
        if ([cluster hasCenter]) {
            double d = [self distanceBetweenPoints:cluster.coordinate p2:marker.coordinate];
            if (d < distance) {
                distance = d;
                clusterToAddTo = cluster;
            }
        }
    }
    
    if (clusterToAddTo && [clusterToAddTo isMarkerInClusterBounds:marker]) {
        [clusterToAddTo addMarker:marker];
    } else {
        RECluster *cluster = [[RECluster alloc] initWithClusterer:self];
        [cluster addMarker:marker];
        [_clusters addObject:cluster];
    }
}

- (void)createClusters
{
    [_clusters removeAllObjects];
    for (REMarker *marker in _markers) {
        if (marker.coordinate.latitude == 0 && marker.coordinate.longitude == 0) 
            continue;
        if ([self markerInBounds:marker])
             [self addToClosestCluster:marker];
    }
}

- (void)removeAnnotation:(RECluster *)annotation views:(NSArray *)views
{
    MKAnnotationView* anView = [_mapView viewForAnnotation: annotation];
    
    CGRect endFrame;    
    CGPoint closest = [self findClosestAnnotationX:anView.frame.origin.x y:anView.frame.origin.y views:views];
    BOOL skipAnimations = NO;
    
    if (closest.x != 0 && closest.y != 0) {
        endFrame = CGRectMake(closest.x, 
                                  closest.y, 
                                  anView.frame.size.width, 
                                  anView.frame.size.height);
    } else {
        skipAnimations = YES;
        endFrame = anView.frame;
    }
    
    if (skipAnimations) return;
    
    _isRedrawing = YES;
    
    __typeof (&*self) __weak weakSelf = self;
    
    [UIView animateWithDuration:0.25 delay:0 
                        options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{ 
                         [anView setFrame:endFrame];
                     }  completion:^(BOOL finished){
                         [weakSelf.mapView removeAnnotation:annotation];
                         weakSelf.isRedrawing = NO;
                     }];
}

- (void)clusterize
{
    if (_isRedrawing) {
        _needsToRedraw = YES;
        return;
    }

    _tempTimer = nil;
    
    NSMutableArray *remainedAnnotationViews = [[NSMutableArray alloc] init];
    NSMutableArray *annotationsToRemove = [[NSMutableArray alloc] init];
    
    [self createClusters];
    for (NSInteger j=0; j < [_mapView.annotations count]; j++) {
        RECluster *annotation = (RECluster *)[_mapView.annotations objectAtIndex:j];

        // ignore annotations not managed by REMarkerCluster
        if ([annotation isKindOfClass:[RECluster class]] == NO) {
            continue;
        }

        RECluster *fromCluster;
        BOOL found = NO;
        for (NSInteger i=0; i < [_clusters count]; i++) {
            fromCluster = (RECluster *)[_clusters objectAtIndex:i];
            if (fromCluster.coordinate.latitude == annotation.coordinate.latitude &&
                fromCluster.coordinate.longitude == annotation.coordinate.longitude) {
                found = YES;
                break;
            }
        }
        if (!found) {
            [annotationsToRemove addObject:annotation];
        } else {
            if ([_mapView viewForAnnotation:annotation] != nil)
                [remainedAnnotationViews addObject:[_mapView viewForAnnotation:annotation]];
            
            if ([annotation isKindOfClass:[RECluster class]]) {
                [annotation.markers removeAllObjects];
                [annotation.markers addObjectsFromArray:fromCluster.markers];
                if ([annotation.markers count] == 1) {
                    REMarker *marker = [annotation.markers objectAtIndex:0];
                    annotation.title = marker.title;
                    annotation.subtitle = marker.subtitle;
                } else {
                    annotation.title = [NSString stringWithFormat:_clusterTitle, [annotation.markers count]];
                    annotation.subtitle = nil;
                }
            }
        }
    }

    for (RECluster *annotation in annotationsToRemove) {
        [self removeAnnotation:annotation views:remainedAnnotationViews];
    }
    
    [_tempViews removeAllObjects];
    [_tempViews addObjectsFromArray:remainedAnnotationViews];
    
    for (NSInteger i=0; i < [_clusters count]; i++) {
        RECluster *cluster = (RECluster *)[_clusters objectAtIndex:i];
        BOOL found = NO;
        for (NSInteger j=0; j < [_mapView.annotations count]; j++) {
            REMarker *annotation = (REMarker *)[_mapView.annotations objectAtIndex:j];
            if (cluster.coordinate.latitude == annotation.coordinate.latitude &&
                cluster.coordinate.longitude == annotation.coordinate.longitude) 
                found = YES;
        }
        if (found) {
            continue;
        }

        if ([cluster.markers count] == 1) {
            REMarker *marker = [cluster.markers objectAtIndex:0];
            cluster.title = marker.title;
        } else {
            cluster.title = [NSString stringWithFormat:_clusterTitle, [cluster.markers count]];
        }
        [self.mapView addAnnotation:cluster];
    }
}

- (CGPoint)findClosestAnnotationX:(double)x y:(double)y
{
    return [self findClosestAnnotationX:x y:y views:_tempViews];
}

- (CGPoint)findClosestAnnotationX:(double)x y:(double)y views:(NSArray *)views
{
    CGPoint result = CGPointMake(0, 0);
    double diff = 10000;
    for (NSInteger i=0; i < [views count]; i++){
        MKAnnotationView* anView = [views objectAtIndex:i];
        if (anView){
            CGPoint pos = anView.frame.origin;
            double newDiff = sqrt((x - pos.x) * (x - pos.x) + (y - pos.y) * (y - pos.y));
            if (newDiff < diff) {
                result = pos;
                diff = newDiff;
            }
        }
    }
    if (diff > 80) return CGPointMake(0, 0);
    return result;
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    if ([_delegate respondsToSelector:@selector(mapView:regionWillChangeAnimated:)])
        [_delegate mapView:mapView regionWillChangeAnimated:animated];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self clusterize];
    NSArray *selectedAnnotations = self.mapView.selectedAnnotations;
    RECluster *selectedAnnotation = [selectedAnnotations objectAtIndex:0];
    [self.mapView deselectAnnotation:selectedAnnotation animated:NO];
    
    if ([_delegate respondsToSelector:@selector(mapView:regionDidChangeAnimated:)])
        [_delegate mapView:mapView regionDidChangeAnimated:animated];
}

- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView
{
    if ([_delegate respondsToSelector:@selector(mapViewWillStartLoadingMap:)])
        [_delegate mapViewWillStartLoadingMap:mapView];
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    if ([_delegate respondsToSelector:@selector(mapViewDidFinishLoadingMap:)])
        [_delegate mapViewDidFinishLoadingMap:mapView];
}

- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error
{
    if ([_delegate respondsToSelector:@selector(mapViewDidFailLoadingMap:withError:)])
        [_delegate mapViewDidFailLoadingMap:mapView withError:error];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([_delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
        return [_delegate mapView:mapView viewForAnnotation:annotation];
    }
    
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
	
	MKPinAnnotationView *pinView = nil;
    
	static NSString *pinID = @"REMarkerClustererPin";
    
	pinView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:pinID];
    
	if (pinView == nil) {
		pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pinID];
        
        UIButton *detailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        detailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        detailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        detailButton.tag = 1;
        pinView.rightCalloutAccessoryView = detailButton;
    }
	
	pinView.pinColor = MKPinAnnotationColorRed;
    pinView.canShowCallout = YES;
    return pinView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    for (MKAnnotationView *annotationView in views) {
        CGRect endFrame = annotationView.frame;
        
        CGPoint closest = [self findClosestAnnotationX:annotationView.frame.origin.x y:annotationView.frame.origin.y];
        BOOL skipAnimations = NO;
        
        if (closest.x != 0 && closest.y != 0) {
            annotationView.frame = CGRectMake(closest.x,
                                              closest.y,
                                              annotationView.frame.size.width,
                                              annotationView.frame.size.height);
        } else {
            skipAnimations = YES;
            annotationView.frame = CGRectMake(annotationView.frame.origin.x,
                                              annotationView.frame.origin.y,
                                              annotationView.frame.size.width,
                                              annotationView.frame.size.height);
        }
        
        if (skipAnimations) continue;
        
        _isRedrawing = YES;
        
        [UIView animateWithDuration:0.25 delay:0
                            options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [annotationView setFrame:endFrame];
                         }  completion:^(BOOL finished){
                             _isRedrawing = NO;
                         }];
    }
    
    if ([_delegate respondsToSelector:@selector(mapView:didAddAnnotationViews:)]) {
        [_delegate mapView:mapView didAddAnnotationViews:views];
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([_delegate respondsToSelector:@selector(mapView:annotationView:calloutAccessoryControlTapped:)])
        [_delegate mapView:mapView annotationView:view calloutAccessoryControlTapped:control];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view NS_AVAILABLE(NA, 4_0)
{
    if ([_delegate respondsToSelector:@selector(mapView:didSelectAnnotationView:)])
        [_delegate mapView:mapView didSelectAnnotationView:view];
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view NS_AVAILABLE(NA, 4_0)
{
    if ([_delegate respondsToSelector:@selector(mapView:didDeselectAnnotationView:)])
        [_delegate mapView:mapView didDeselectAnnotationView:view];
}

- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView NS_AVAILABLE(NA, 4_0)
{
    if ([_delegate respondsToSelector:@selector(mapViewWillStartLocatingUser:)])
        [_delegate mapViewWillStartLocatingUser:mapView];
}

- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView NS_AVAILABLE(NA, 4_0)
{
    if ([_delegate respondsToSelector:@selector(mapViewDidStopLocatingUser:)])
        [_delegate mapViewDidStopLocatingUser:mapView];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation NS_AVAILABLE(NA, 4_0)
{
    if ([_delegate respondsToSelector:@selector(mapView:didUpdateUserLocation:)])
        [_delegate mapView:mapView didUpdateUserLocation:userLocation];
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error NS_AVAILABLE(NA, 4_0)
{
    if ([_delegate respondsToSelector:@selector(mapView:didFailToLocateUserWithError:)])
        [_delegate mapView:mapView didFailToLocateUserWithError:error];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState
fromOldState:(MKAnnotationViewDragState)oldState NS_AVAILABLE(NA, 4_0)
{
    if ([_delegate respondsToSelector:@selector(mapView:annotationView:didChangeDragState:fromOldState:)])
        [_delegate mapView:mapView annotationView:view didChangeDragState:newState fromOldState:oldState];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay NS_AVAILABLE(NA, 4_0)
{
    if ([_delegate respondsToSelector:@selector(mapView:viewForOverlay:)])
        return [_delegate mapView:mapView viewForOverlay:overlay];
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didAddOverlayViews:(NSArray *)overlayViews NS_AVAILABLE(NA, 4_0)
{
    if ([_delegate respondsToSelector:@selector(mapView:didAddOverlayViews:)])
        [_delegate mapView:mapView didAddOverlayViews:overlayViews];
}

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated NS_AVAILABLE(NA, 5_0)
{
    if ([_delegate respondsToSelector:@selector(mapView:didChangeUserTrackingMode:animated:)])
        [_delegate mapView:mapView didChangeUserTrackingMode:mode animated:animated];
}

@end
