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

#define mixesKey @"mixesKey"
#define mergeatorsKey @"remainedKey"

@interface REMarkerClusterer ()

@property (assign, readwrite, nonatomic) BOOL animating;
@property (strong, readonly, nonatomic) NSArray *markerAnnotations;

@end

@implementation REMarkerClusterer

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    
    _gridSize = 25;
    _maxDelayOfSplitAnimation = 0;
    _maxDelayOfSplitAnimation = 0.25;
    _tempViews = [[NSMutableArray alloc] init];
    _markers = [[NSMutableArray alloc] init];
    _clusters = [[NSMutableArray alloc] init];
    
    _clusterTitle = @"%i items";
    
    return self;
}

- (id)initWithMapView:(MKMapView *)mapView delegate:(id<REMarkerClusterDelegate>)delegate
{
    self = [self init];
    if (!self)
        return nil;
    
    self.mapView = mapView;
    self.delegate = delegate;
    
    return self;
}

- (void)dealloc
{
    // Break the MKMapView delegate connection to avoid potential use after
    // free bugs.
    _mapView.delegate = nil;
}

- (void)setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    _mapView.delegate = self;
}

- (void)addMarker:(id<REMarker>)marker
{
    [_markers addObject:marker];
}

- (void)addMarkers:(NSArray*)markers;
{
    [_markers addObjectsFromArray:markers];
}

- (void)removeMarker:(id<REMarker>)marker;
{
    [_markers removeObject:marker];
}

- (void)removeAllMarkers
{
    [_clusters removeAllObjects];
    [_markers removeAllObjects];
    [self.mapView removeAnnotations:self.markerAnnotations];
}

- (void)zoomToAnnotationsBounds:(NSArray *)annotations
{
    CLLocationDegrees minLatitude = DBL_MAX;
    CLLocationDegrees maxLatitude = -DBL_MAX;
    CLLocationDegrees minLongitude = DBL_MAX;
    CLLocationDegrees maxLongitude = -DBL_MAX;
    
    for (id<REMarker>annotation in annotations) {
        CGFloat annotationLat = annotation.coordinate.latitude;
        CGFloat annotationLong = annotation.coordinate.longitude;
        if (annotationLat == 0 && annotationLong == 0)
            continue;
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
    
    CGFloat latitudeSpanToBeAddedToTop = relativeFromCoord.latitude - topCoord.latitude;
    CGFloat longitudeSpanToBeAddedToRight = relativeFromCoord.latitude - rightCoord.latitude;
    CGFloat latitudeSpanToBeAddedToBottom = relativeFromCoord.latitude - bottomCoord.latitude;
    CGFloat longitudeSpanToBeAddedToLeft = relativeFromCoord.latitude - leftCoord.latitude;
    
    maxLatitude = maxLatitude + latitudeSpanToBeAddedToTop;
    minLatitude = minLatitude - latitudeSpanToBeAddedToBottom;
    
    maxLongitude = maxLongitude + longitudeSpanToBeAddedToRight;
    minLongitude = minLongitude - longitudeSpanToBeAddedToLeft;
    
    [self setMapRegionForMinLat:minLatitude minLong:minLongitude maxLat:maxLatitude maxLong:maxLongitude];
}

- (void)setMapRegionForMinLat:(CGFloat)minLatitude minLong:(CGFloat)minLongitude maxLat:(CGFloat)maxLatitude maxLong:(CGFloat)maxLongitude
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
    //
    if ((region.center.latitude >= -90) && (region.center.latitude <= 90) && (region.center.longitude >= -180) && (region.center.longitude <= 180)) {
        [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
    }
}

- (CGFloat)distanceBetweenPoints:(CLLocationCoordinate2D)p1 p2:(CLLocationCoordinate2D)p2
{
	CGFloat R = 6371; // Radius of the Earth in km
	CGFloat dLat = (p2.latitude - p1.latitude) * M_PI / 180;
	CGFloat dLon = (p2.longitude - p1.longitude) * M_PI / 180;
	CGFloat a = sin(dLat / 2) * sin(dLat / 2) + cos(p1.latitude * M_PI / 180) * cos(p2.latitude * M_PI / 180) * sin(dLon / 2) * sin(dLon / 2);
	CGFloat c = 2 * atan2(sqrt(a), sqrt(1 - a));
	CGFloat d = R * c;
	return d;
}

- (void)addToClosestCluster:(id<REMarker>)marker
{
    CGFloat distance = 40000; // Some large number
    RECluster *clusterToAddTo;
    for (RECluster *cluster in _clusters) {
        if ([cluster hasCenter]) {
            CGFloat d = [self distanceBetweenPoints:cluster.coordinate p2:marker.coordinate];
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
    for (id<REMarker>marker in _markers) {
        if (marker.coordinate.latitude == 0 && marker.coordinate.longitude == 0) 
            continue;

         [self addToClosestCluster:marker];
    }
}

- (void)clusterize
{
    [self clusterize:YES];
}

- (void)addObject:(id) object toDictionary:(NSMutableDictionary *)dictionary withKey:(NSString *)key
{
    NSMutableArray *objectInKey = [dictionary objectForKey:key];
    if(objectInKey == nil){
        objectInKey = [NSMutableArray arrayWithCapacity:0];
        [objectInKey addObject:object];
        [dictionary setObject:objectInKey forKey:key];
    }else{
        [objectInKey addObject:object];
    }
}

- (float)randomFloatBetween:(float)smallNumber and:(float)bigNumber
{
    float diff = bigNumber - smallNumber;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

- (void)splitAnnotationsWithDictionary:(NSDictionary *)dictionary
{
    NSDictionary *mergeators = [dictionary objectForKey:mergeatorsKey];
    NSDictionary *mixes = [dictionary objectForKey:mixesKey];
    
    for (NSString *mergeatorKey in [mergeators allKeys]){
        NSArray *annotations = [mixes objectForKey:mergeatorKey];
        RECluster *endCluster = [mergeators objectForKey:mergeatorKey];
        
        if (_animated) {
            for (RECluster *annotation in annotations) {
                [_mapView addAnnotation:annotation];
                if(annotation.coordinate.latitude != endCluster.coordinate.latitude || annotation.coordinate.longitude != endCluster.coordinate.longitude) {
                    CLLocationCoordinate2D realCoordinate = annotation.coordinate;
                    _animating = YES;
                    annotation.coordinate = endCluster.coordinate;
                    __typeof (&*self) __weak weakSelf = self;
                    [UIView animateWithDuration:[self randomFloatBetween:0.25 and:_maxDurationOfSplitAnimation] delay:[self randomFloatBetween:0 and:_maxDelayOfSplitAnimation]
                                        options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                                     animations:^{
                                         annotation.coordinate = realCoordinate;
                                     }  completion:^(BOOL finished){
                                         weakSelf.animating = NO;
                                         [_mapView removeAnnotation:annotation];
                                         [_mapView addAnnotation:annotation];
                                     }];
                }
                [_mapView removeAnnotation:endCluster];
                
            }
        } else {
            [_mapView addAnnotations:annotations];
            [_mapView removeAnnotation:endCluster];
        }
    }
}

- (void)joinAnnotationsWithDictionary:(NSDictionary *)dictionary
{
    NSDictionary *mergeators = [dictionary objectForKey:mergeatorsKey];
    NSDictionary *mixes = [dictionary objectForKey:mixesKey];
    
    for (NSString *mergeatorKey in [mergeators allKeys]) {
        NSArray *annotations = [mixes objectForKey:mergeatorKey];
        RECluster *endCluster = [mergeators objectForKey:mergeatorKey];
        for (RECluster *annotation in annotations){
            if (_animated) {
                _animating = YES;
                __typeof (&*self) __weak weakSelf = self;
                [UIView animateWithDuration:[self randomFloatBetween:0.25 and:_maxDurationOfSplitAnimation] delay:[self randomFloatBetween:0 and:_maxDelayOfSplitAnimation]
                                    options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                                 animations:^{
                                     annotation.coordinate = endCluster.coordinate;
                                 }  completion:^(BOOL finished){
                                     weakSelf.animating = NO;
                                     if (annotation != [annotations lastObject]) {
                                         [weakSelf.mapView removeAnnotation:annotation];
                                     } else {
                                         [_mapView removeAnnotation:annotation];
                                         [_mapView addAnnotation:annotation];
                                     }
                                 }];
            }else{
                [_mapView removeAnnotations:annotations];
                [_mapView addAnnotation:endCluster];
            }
            ((RECluster *)[annotations lastObject]).title = endCluster.title;
            ((RECluster *)[annotations lastObject]).subtitle = endCluster.subtitle;
            MKAnnotationView *view = [_mapView viewForAnnotation:(_animated)?[annotations lastObject]:endCluster];
            [[view superview] bringSubviewToFront:view];
            if (_animated) ((RECluster *)[annotations lastObject]).markers = endCluster.markers;
            if ([self.delegate respondsToSelector:@selector(markerClusterer:withMapView:updateViewOfAnnotation:withView:)]) {
                [self.delegate markerClusterer:self withMapView:_mapView updateViewOfAnnotation:annotation withView:[_mapView viewForAnnotation:annotation]];
            }
        }
    }
}

- (void)clusterize:(BOOL)animated
{
    if (_animating && animated)
        return;
        
    _animated = animated;
    
    [self createClusters];
    
    NSMutableDictionary *mixDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
    NSMutableArray *remainingAnnotations = [NSMutableArray arrayWithCapacity:0];
    
    for (RECluster *cluster in ((self.markerAnnotations.count > _clusters.count) ? self.markerAnnotations : _clusters)) {
        NSInteger numberOfMarkers = 1;
        NSMutableArray *posiblesArrays = [NSMutableArray arrayWithCapacity:0];
        for (RECluster *cluster2 in ((self.markerAnnotations.count <= _clusters.count)?self.markerAnnotations:_clusters)) {
            NSInteger markers = [cluster markersInClusterFromMarkers:cluster2.markers];
            if(markers >= numberOfMarkers){
                [posiblesArrays addObject:cluster2];
                numberOfMarkers = markers;
            }
        }
        
        if (posiblesArrays.count == 1) {
            [self addObject:cluster toDictionary:mixDictionary withKey:((RECluster *)[posiblesArrays lastObject]).coordinateTag];
        } else if(posiblesArrays.count == 0) {
            [remainingAnnotations addObject:cluster];
        } else {
            NSInteger minor = INT16_MAX;
            NSInteger index = posiblesArrays.count-1;
            for (RECluster *cluster2 in posiblesArrays) {
                if (cluster2.markers.count < minor) {
                    index = [posiblesArrays indexOfObject:cluster2];
                    minor = cluster2.markers.count;
                }
            }
            [self addObject:cluster toDictionary:mixDictionary withKey:((RECluster *)[posiblesArrays objectAtIndex:index]).coordinateTag];
        }
    }
    
    NSMutableDictionary *mergeators = [NSMutableDictionary dictionaryWithCapacity:0];
    
    for (RECluster *cluster in ((self.markerAnnotations.count <= _clusters.count) ? self.markerAnnotations : _clusters)) {
        [mergeators setObject:cluster forKey:cluster.coordinateTag];
    }
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         mergeators,mergeatorsKey,
                         mixDictionary,mixesKey,
                         nil];
    
    if (self.markerAnnotations.count == 0) {
        [_mapView addAnnotations:_clusters];
    }
    else if (self.markerAnnotations.count > _clusters.count) {
        [self joinAnnotationsWithDictionary:dic];
        //[self addAnnotationsWithOutSpliting:remainingAnnotations];
    } else if(self.markerAnnotations.count < _clusters.count) {
        [self splitAnnotationsWithDictionary:dic];
    } else {
    }

}

- (BOOL)isAnimating
{
    return _animating;
}

- (CGPoint)findClosestAnnotationX:(CGFloat)x y:(CGFloat)y
{
    return [self findClosestAnnotationX:x y:y views:_tempViews];
}

- (CGPoint)findClosestAnnotationX:(CGFloat)x y:(CGFloat)y views:(NSArray *)views
{
    CGPoint result = CGPointMake(0, 0);
    CGFloat diff = 10000;
    for (NSInteger i=0; i < [views count]; i++) {
        MKAnnotationView* anView = [views objectAtIndex:i];
        if (anView) {
            CGPoint pos = anView.frame.origin;
            CGFloat newDiff = sqrt((x - pos.x) * (x - pos.x) + (y - pos.y) * (y - pos.y));
            if (newDiff < diff) {
                result = pos;
                diff = newDiff;
            }
        }
    }
    if (diff > 80)
        return CGPointZero;
    
    return result;
}

- (NSArray *)markerAnnotations
{
    NSMutableArray *annotations = [NSMutableArray array];
    for (NSObject *annotation in self.mapView.annotations) {
        if (![annotation isKindOfClass:[RECluster class]])
            continue;
        
        [annotations addObject:annotation];
    }
    return annotations;
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
    [self clusterize:YES];
    [self.mapView deselectAnnotation:[self.mapView.selectedAnnotations objectAtIndex:0] animated:NO];
    
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

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([_delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
        return [_delegate mapView:mapView viewForAnnotation:annotation];
    }
    
    if (![annotation isKindOfClass:[RECluster class]])
        return nil;
    
	static NSString *pinID = @"REMarkerClustererPin";
    
	MKPinAnnotationView *pinView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:pinID];
    
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

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState NS_AVAILABLE(NA, 4_0)
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

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    if ([_delegate respondsToSelector:@selector(mapView:rendererForOverlay:)]) {
        return [_delegate mapView:mapView rendererForOverlay:overlay];
    }
    return nil;
}

-(void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered
{
    if ([_delegate respondsToSelector:@selector(mapViewDidFinishRenderingMap:fullyRendered:)])
        [_delegate mapViewDidFinishRenderingMap:mapView fullyRendered:fullyRendered];
}

@end
