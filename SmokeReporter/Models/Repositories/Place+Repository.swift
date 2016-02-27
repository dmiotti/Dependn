//
//  Place+Repository.swift
//  SmokeReporter
//
//  Created by David Miotti on 25/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import CoreData

extension Place {
    static func insertNewPlace(
        name: String?,
        latitude: Double,
        longitude: Double,
        inContext context: NSManagedObjectContext = CoreDataStack.shared.managedObjectContext) -> Place {
            
            let place = NSEntityDescription.insertNewObjectForEntityForName(Place.entityName, inManagedObjectContext: context) as! Place
            
            place.name = name
            place.lat = latitude
            place.lon = longitude
        
            return place
    }
}
