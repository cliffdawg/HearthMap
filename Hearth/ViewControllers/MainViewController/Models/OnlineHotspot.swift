//
//  OnlineHotspot.swift
//  Hearth
//
//  Created by Clifford Yin on 5/28/17.
//  Copyright © 2017 Clifford Yin. All rights reserved.
//

import Foundation

/* Code that constitutes an "online hotspot" entity */
class OnlineHotspot{

    var address: String!
    var frequency: Int!
    var lat: Double!
    var long: Double!
    
    init(add: String, freq: Int, lati: Double, longi: Double){
        self.address = add
        self.frequency = freq
        self.lat = lati
        self.long = longi
    }
}
