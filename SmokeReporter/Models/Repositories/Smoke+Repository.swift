//
//  Smoke+Repository.swift
//  SmokeReporter
//
//  Created by David Miotti on 25/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import CoreData
import CocoaLumberjackSwift
import CoreLocation

private let R: Double = 6371009000

extension Smoke {
    
    static func insertNewSmoke(type: SmokeType,
        intensity: Float,
        before: String?,
        after: String?,
        comment: String?,
        place: String?,
        latitude: Double?,
        longitude: Double?,
        date: NSDate = NSDate(),
        inContext context: NSManagedObjectContext) -> Smoke {
            let smoke = NSEntityDescription
                .insertNewObjectForEntityForName(Smoke.entityName,
                    inManagedObjectContext: context) as! Smoke
            smoke.intensity = intensity
            smoke.type = type == .Cig ? SmokeTypeCig : SmokeTypeWeed
            smoke.before = before
            smoke.after = after
            smoke.comment = comment
            smoke.place = place
            smoke.lat = latitude
            smoke.lon = longitude
            smoke.date = date
            return smoke
    }
    
    static func historyFetchedResultsController(inContext context: NSManagedObjectContext) -> NSFetchedResultsController {
        let req = NSFetchRequest(entityName: Smoke.entityName)
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        let controller = NSFetchedResultsController(fetchRequest: req,
            managedObjectContext: context,
            sectionNameKeyPath: "sectionIdentifier",
            cacheName: nil)
        return controller
    }
    
    static func deleteSmoke(smoke: Smoke) {
        CoreDataStack.shared.managedObjectContext.deleteObject(smoke)
    }
    
    static func findNearBySmoke(latitude: Double, longitude: Double, inContext context: NSManagedObjectContext) -> Smoke? {
        // We want to search within ±150 meters
        let D: Double = 150.0 * 1.1
        let meanLat = latitude * M_PI / 180.0
        let deltaLat = D / R * 180.0 / M_PI
        let deltaLon = D / (R * cos(meanLat)) * 180.0 / M_PI
        let minLat = latitude - deltaLat
        let maxLat = latitude + deltaLat
        let minLon = longitude - deltaLon
        let maxLon = longitude + deltaLon
        let req = NSFetchRequest(entityName: Smoke.entityName)
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        req.predicate = NSPredicate(format:
            "(%@ <= lon) AND (lon <= %@) AND (%@ <= lat) AND (lat <= %@) AND (place != nil)",
            NSNumber(double: minLon), NSNumber(double: maxLon), NSNumber(double: minLat), NSNumber(double: maxLat))
        req.fetchLimit = 50
        do {
            return try context.executeFetchRequest(req).first as? Smoke
        } catch let err as NSError {
            DDLogError("Error while fetching places: \(err)")
        }
        return nil
    }
    
}