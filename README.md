# REMarkerClusterer
###REMarkerClusterer creates and manages per-zoom-level clusters for large amounts of markers.

As seen in [Pinsnap](http://itunes.apple.com/us/app/pinsnap/id457407067?mt=8) iPhone app. `REMarkerClusterer` was inspired by the Apple Photos app on the iPhone, `REMarkerClusterer` mimics it's behaviour providing animations for grouping and ungrouping clusters.

<img src="https://github.com/romaonthego/REMarkerClusterer/raw/master/Screenshot.jpg" alt="REMarkerClusterer Screenshot" width="320" height="480" />

## How it works
The `REMarkerClusterer` will group markers into clusters according to their distance from a cluster's center. When a marker is added, the marker cluster will find a position in all the clusters, and if it fails to find one, it will create a new cluster with the marker. The number of markers in a cluster will be displayed on the cluster marker. When the map viewport changes, `REMarkerClusterer` will destroy the clusters in the viewport and regroup them into new clusters.

## Requirements
* Xcode 4.6 or higher
* Apple LLVM compiler
* iOS 5.0 or higher
* ARC (if you want to use in a project without ARC just add the flag `-fobjc-arc` to the files in the Build Phases tab of your project)

## Demo

Build and run the `REMarkerClustererExample` project in Xcode to see `REMarkerClusterer` in action.

## Installation

### CocoaPods

The recommended approach for installating `REMarkerClusterer` is via the [CocoaPods](http://cocoapods.org/) package manager, as it provides flexible dependency management and dead simple installation.
For best results, it is recommended that you install via CocoaPods >= **0.15.2** using Git >= **1.8.0** installed via Homebrew.

Install CocoaPods if not already available:

``` bash
$ [sudo] gem install cocoapods
$ pod setup
```

Change to the directory of your Xcode project:

``` bash
$ cd /path/to/MyProject
$ touch Podfile
$ edit Podfile
```

Edit your Podfile and add REMarkerClusterer:

``` bash
platform :ios, '5.0'
pod 'REMarkerClusterer', '~> 2.1.3'
```

Install into your Xcode project:

``` bash
$ pod install
```

Open your project in Xcode from the .xcworkspace file (not the usual project file)

``` bash
$ open MyProject.xcworkspace
```

Please note that if your installation fails, it may be because you are installing with a version of Git lower than CocoaPods is expecting. Please ensure that you are running Git >= **1.8.0** by executing `git --version`. You can get a full picture of the installation details by executing `pod install --verbose`.

### Manual Install

`REMarkerClusterer` requires the `MapKit` and `CoreLocation` frameworks, so the first thing you'll need to do is include the frameworks into your project.

Now that the framework has been linked, all you need to do is drop files from `REMarkerClusterer` folder into your project, and add `#include "REMarkerClusterer.h"` to the top of classes that will use it.

## Example Usage

``` objective-c
// Add map view
//
_mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
_mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
[self.view addSubview:_mapView];

// Create clusterer, assign a map view and delegate (MKMapViewDelegate)
//
_clusterer = [[REMarkerClusterer alloc] initWithMapView:_mapView delegate:self];

// Set smaller grid size for an iPad
//
_clusterer.gridSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 25 : 20;
_clusterer.clusterTitle = @"%i items";

// Populate with sample data
//
NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Points" ofType:@"plist"]];
NSInteger index = 0;
for (NSDictionary *dict in [data objectForKey:@"Points"]) {
    REMarker *marker = [[REMarker alloc] init];
    marker.markerId = [[dict objectForKey:@"id"] intValue];
    marker.coordinate = CLLocationCoordinate2DMake([[dict objectForKey:@"latitude"] floatValue], [[dict objectForKey:@"longitude"] floatValue]);
    marker.title = [NSString stringWithFormat:@"One item <id: %i>", index];
    marker.userInfo = @{@"index": @(index)};
    [_clusterer addMarker:marker];
    index++;
}

// Create clusters
//
[_clusterer clusterize];

// Zoom to show all clusters/markers on the map
//
[_clusterer zoomToAnnotationsBounds:_clusterer.markers];
```

## Contributors

Nicolas Yuste ([@nicoyuste](https://github.com/nicoyuste))

## Contact

Roman Efimov

- http://github.com/romaonthego
- http://twitter.com/romaonthego
- romefimov@gmail.com

## Credits

Partially based on MarkerClusterer Javascript library by Xiaoxi Wu (http://gmaps-utility-library-dev.googlecode.com)

## License

REMarkerClusterer is available under the MIT license.

Copyright © 2011-2013 Roman Efimov.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
