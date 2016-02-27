//
//  Place.swift
//  SmokeReporter
//
//  Created by David Miotti on 25/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

final class Place: NSManagedObject, NamedEntity {
    
    static var entityName: String { get { return "Place" } }
    
    var coordinate: CLLocationCoordinate2D? {
        if let latitude = lat?.doubleValue, longitude = lon?.doubleValue {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        return nil
    }

}
