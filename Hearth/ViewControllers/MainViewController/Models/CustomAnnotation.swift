//
//  CustomAnnotation.swift
//  Hearth
//
//  Created by Clifford Yin on 3/25/17.
//  Copyright © 2017 Clifford Yin. All rights reserved.
//
//

import UIKit
import MapKit

class CustomAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var detailURL: NSURL
    var enableInfoButton: Bool
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, detailURL: NSURL, enableInfoButton: Bool) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.detailURL = detailURL
        self.enableInfoButton = enableInfoButton
        super.init();
    }
    
    
}
