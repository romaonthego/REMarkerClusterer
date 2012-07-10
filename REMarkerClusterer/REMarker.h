//
//  REMarker.h
//  REMarkerClusterer
//
//  Created by Roman Efimov on 3/8/11.
//  Copyright 2011 Roman Efimov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>

@interface REMarker : NSObject <MKAnnotation> {
	CLLocationCoordinate2D coordinate;
	NSString *title;
    int ID;
}

@property (nonatomic, readwrite) int ID;
@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;

@end

