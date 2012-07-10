//
//  REMarkerClusterer.m
//  REMarkerClusterer
//
//  Created by Roman Efimov on 3/8/11.
//  Copyright 2011 Roman Efimov. All rights reserved.
//

#import "REMarkerClusterer.h"
#import "RECluster.h"
#import <CoreLocation/CLLocation.h>
#import <MapKit/MKGeometry.h>
#import <MapKit/MapKit.h>
#import <MapKit/MKAnnotation.h>

@implementation REMarkerClusterer

@synthesize markers, clusters, mapView, gridSize;

@synthesize isRedrawing, needsToRedraw;

@synthesize delegate;

static bool averageCenter = NO;
static double prevZoom;

- (void)addMarker:(REMarker *)marker
{
    [markers addObject:marker];
}

- (void)baseInit {
    markers = [[NSMutableArray alloc] initWithCapacity:0];
    clusters = [[NSMutableArray alloc] initWithCapacity:0];
}

// Initialization
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self baseInit];
        mapView = [[MKMapView alloc] initWithFrame:frame];
        mapView.delegate = self;
        gridSize = 25;
        tempViews = [[NSMutableArray alloc] initWithCapacity:0];
        [self addSubview:mapView];
    }
    return self;
}

- (bool)markerInBounds:(REMarker *)marker {
    CGPoint pix = [self.mapView convertCoordinate:marker.coordinate toPointToView:nil];
    if (pix.x >=-150 && pix.x <= mapView.frame.size.width+150) {
        if (pix.y >=-150 && pix.y <= mapView.frame.size.height+150) {
            return YES;
        }
    }
    return NO;
}

- (void)zoomToAnnotationsBounds:(NSArray *)annotations {
    
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

- (void) setMapRegionForMinLat:(double)minLatitude minLong:(double)minLongitude maxLat:(double)maxLatitude maxLong:(double)maxLongitude {
    
    MKCoordinateRegion region;
    region.center.latitude = (minLatitude + maxLatitude) / 2;
    region.center.longitude = (minLongitude + maxLongitude) / 2;
    region.span.latitudeDelta = (maxLatitude - minLatitude);
    region.span.longitudeDelta = (maxLongitude - minLongitude);
    
   // NSLog(@"1: %f, 2: %f", region.span.latitudeDelta, region.span.longitudeDelta);
    
    if (region.span.latitudeDelta < 0.059863)
        region.span.latitudeDelta = 0.059863;
    
    if (region.span.longitudeDelta < 0.059863)
        region.span.longitudeDelta = 0.059863;
    
    // MKMapView BUG: this snaps to the nearest whole zoom level, which is wrong- it doesn't respect the exact region you asked for. See http://stackoverflow.com/questions/1383296/why-mkmapview-region-is-different-than-requested
    [self.mapView setRegion:region animated:YES];
}


- (void)setLatitude:(double)latitude longitude:(double)longitude delta:(double)delta {
    MKCoordinateRegion newRegion;
    newRegion.center.latitude = latitude;
    newRegion.center.longitude = longitude;
    newRegion.span.latitudeDelta = delta;
    newRegion.span.longitudeDelta = delta;
    prevZoom = mapView.region.span.latitudeDelta;
    [self.mapView setRegion:newRegion animated:YES];
}


- (double)distanceBetweenPoints:(CLLocationCoordinate2D)p1 p2:(CLLocationCoordinate2D)p2 {
	double R = 6371; // Radius of the Earth in km
	double dLat = (p2.latitude - p1.latitude) * M_PI / 180;
	double dLon = (p2.longitude - p1.longitude) * M_PI / 180;
	double a = sin(dLat / 2) * sin(dLat / 2) + cos(p1.latitude * M_PI / 180) * cos(p2.latitude * M_PI / 180) * sin(dLon / 2) * sin(dLon / 2);
	double c = 2 * atan2(sqrt(a), sqrt(1 - a));
	double d = R * c;
	return d;
}

- (void)addToClosestCluster:(REMarker *)marker {
    double distance = 40000; // Some large number
    RECluster *clusterToAddTo = nil;
    for (int i = 0; i < [clusters count]; i++) {
        RECluster *cluster = (RECluster *)[clusters objectAtIndex:i];
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
        [clusters addObject:cluster];
    }
}

- (void)createClusters {
    [clusters removeAllObjects];
    for (int i = 0; i < [markers count]; i++) {
        REMarker *marker = (REMarker *)[markers objectAtIndex:i];
        if (marker.coordinate.latitude == 0 && marker.coordinate.longitude == 0) 
            continue;
        if ([self markerInBounds:marker])
             [self addToClosestCluster:marker];
    }
    
    /*for (RECluster *cluster in clusters) {
        [cluster setAverageCenter];
        break;
    }*/
}

- (void)removeAnnotation:(RECluster *)annotation views:(NSArray *)views{
    MKAnnotationView* anView = [mapView viewForAnnotation: annotation];
    
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
    
    isRedrawing = YES;
    
    [UIView animateWithDuration:0.25 delay:0 
                        options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{ 
                         [anView setFrame:endFrame];
                     }  completion:^(BOOL finished){
                         [mapView removeAnnotation:annotation];
                         isRedrawing = NO;
                     }];
}

// Refresh map
- (void)clusterize {
    if (isRedrawing) {
        needsToRedraw = YES;
        return;
    }
//    NSLog(@"redraw");
    tempTimer = nil;
    
    NSMutableArray *remainedAnnotationViews = [[NSMutableArray alloc] init];
    NSMutableArray *annotationsToRemove = [[NSMutableArray alloc] init];
    
    [self createClusters];
    for (int j=0; j < [mapView.annotations count]; j++) {
        RECluster *annotation = (RECluster *)[mapView.annotations objectAtIndex:j];
        RECluster *fromCluster;
        BOOL found = NO;
        for (int i=0; i < [clusters count]; i++) {
            fromCluster = (RECluster *)[clusters objectAtIndex:i];
            if (fromCluster.coordinate.latitude == annotation.coordinate.latitude &&
                fromCluster.coordinate.longitude == annotation.coordinate.longitude) {
                found = YES;
                break;
            }
        }
        if (!found) {
            
            //[self removeAnnotation:annotation];
            [annotationsToRemove addObject:annotation];
        } else {
            if ([mapView viewForAnnotation:annotation] != nil)
                [remainedAnnotationViews addObject:[mapView viewForAnnotation:annotation]];
            
            
            if ([annotation isKindOfClass:[RECluster class]]) {
                [annotation.markers removeAllObjects];
                [annotation.markers addObjectsFromArray:fromCluster.markers];
                //annotation.title = [NSString stringWithFormat:@"count = %i", [annotation.markers count]];
                if ([annotation.markers count] == 1) annotation.title = @"One photo"; else
                    annotation.title = [NSString stringWithFormat:@"%i photos", [annotation.markers count]];
            }
        }
    }
    
    // Remove annotations
    for (RECluster *annotation in annotationsToRemove) {
        [self removeAnnotation:annotation views:remainedAnnotationViews];
    }
    
    [tempViews removeAllObjects];
    [tempViews addObjectsFromArray:remainedAnnotationViews];
    
    
    
    /*[tempViews removeAllObjects];
    for (id<MKAnnotation> annotation in mapView.annotations){
        MKAnnotationView* anView = [mapView viewForAnnotation: annotation];
        if (anView){
            [tempViews addObject:anView];
        }
    }*/
    
    
    for (int i=0; i < [clusters count]; i++) {
        RECluster *cluster = (RECluster *)[clusters objectAtIndex:i];
        BOOL found = NO;
        for (int j=0; j < [mapView.annotations count]; j++) {
            REMarker *annotation = (REMarker *)[mapView.annotations objectAtIndex:j];
            if (cluster.coordinate.latitude == annotation.coordinate.latitude &&
                cluster.coordinate.longitude == annotation.coordinate.longitude) 
                found = YES;
        }
        if (found) {
            continue;
        }
        
        //if ([cluster.markers count] == 1) {
          //  [self.mapView addAnnotation:cluster];
            //[self.mapView addAnnotation:[cluster.markers objectAtIndex:0]];
        //} else {
        NSLog(@"count = %i", [cluster.markers count]);
            if ([cluster.markers count] == 1) cluster.title = @"One photo"; else
                cluster.title = [NSString stringWithFormat:@"%i photos", [cluster.markers count]];
            [self.mapView addAnnotation:cluster];
        //}
    }
}

- (int)getGridSize {
    return gridSize;
}

- (bool)isAverageCenter {
    return averageCenter;
}

- (CGPoint)findClosestAnnotationX:(double)x y:(double)y {
    return [self findClosestAnnotationX:x y:y views:tempViews];
}

- (CGPoint)findClosestAnnotationX:(double)x y:(double)y views:(NSArray *)views {
    CGPoint result = CGPointMake(0, 0);
    double diff = 10000;
    for (int i=0; i < [views count]; i++){
        MKAnnotationView* anView = [views objectAtIndex:i];
        if (anView){
            CGPoint pos = anView.frame.origin;
            double newDiff = sqrt((x - pos.x) * (x - pos.x) + (y - pos.y) * (y - pos.y));
            if (newDiff < diff /*&& (pos.x != x && pos.y != y)*/) {
                result = pos;
                diff = newDiff;
            }
        }
    }
    //NSLog(@"diff = %f", diff);
    if (diff > 80) return CGPointMake(0, 0);
    return result;
}


#pragma mark MapView delegate

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views { 
    MKAnnotationView *aV;
    for (aV in views) {
        CGRect endFrame = aV.frame;
        
        CGPoint closest = [self findClosestAnnotationX:aV.frame.origin.x y:aV.frame.origin.y];
        BOOL skipAnimations = NO;
        
        if (closest.x != 0 && closest.y != 0) {
            aV.frame = CGRectMake(closest.x, 
                                  closest.y, 
                                  aV.frame.size.width, 
                                  aV.frame.size.height);
        } else {
            skipAnimations = YES;
            aV.frame = CGRectMake(aV.frame.origin.x, 
                                  aV.frame.origin.y, 
                                  aV.frame.size.width, 
                                  aV.frame.size.height);
        }
        
        if (skipAnimations) continue;
        
        isRedrawing = YES;
        
        [UIView animateWithDuration:0.25 delay:0 
                            options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{ 
                             [aV setFrame:endFrame];
                         }  completion:^(BOOL finished){
                            isRedrawing = NO;
                         }];
    }
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
	RECluster *cluster = view.annotation;
    [delegate performSelector:@selector(clusterPressedWithItems:) withObject:cluster.markers];
}

- (MKAnnotationView *)mapView:(MKMapView *)mV viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
	
	MKPinAnnotationView *pinView = nil;
	static NSString *defaultPinID = @"defaultPinID";
	pinView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:defaultPinID];
	if ( pinView == nil )
		pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:defaultPinID];
	
	pinView.pinColor = MKPinAnnotationColorRed;
    
    pinView.canShowCallout = YES;
    
    UIButton *detailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    detailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    detailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    detailButton.tag = 1;
    pinView.rightCalloutAccessoryView = detailButton;
	
    return pinView;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self clusterize];
    
    NSArray *selectedAnnotations = self.mapView.selectedAnnotations;
    RECluster *selectedAnnotation = [selectedAnnotations objectAtIndex:0];
    [self.mapView deselectAnnotation:selectedAnnotation animated:NO];
}


@end
