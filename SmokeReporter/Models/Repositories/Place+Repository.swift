//
//  Place+Repository.swift
//  SmokeReporter
//
//  Created by David Miotti on 25/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import CoreData
import CocoaLumberjackSwift

private let D: Double = 88
private let R: Double = 6371009

extension Place {
    static func insertNewPlace(
        name: String?,
        latitude: Double,
        longitude: Double,
        inContext context: NSManagedObjectContext) -> Place {
            let place = NSEntityDescription.insertNewObjectForEntityForName(
                Place.entityName, inManagedObjectContext: context) as! Place
            place.name = name
            place.lat = latitude
            place.lon = longitude
            return place
    }
    
    static func findPlaceNearBy(latitude: Double, longitude: Double, inContext context: NSManagedObjectContext) -> Place? {
        let meanLat = latitude * M_PI / 180
        let deltaLat = D / R * 180 / M_PI
        let deltaLon = D / (R * cos(meanLat)) * 180 / M_PI
        let minLat = latitude - deltaLat
        let maxLat = latitude + deltaLat
        let minLon = longitude - deltaLon
        let maxLon = longitude + deltaLon
        let req = NSFetchRequest(entityName: Place.entityName)
        req.predicate = NSPredicate(format: "%@ <= lon AND lon <= %@ AND %@ <= lat AND lat <= %@", minLon, maxLon, minLat, maxLat)
        do {
            return try context.executeFetchRequest(req).first as? Place
        } catch let err as NSError {
            DDLogError("Error while fetching places: \(err)")
        }
        return nil
    }
}
