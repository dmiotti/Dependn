//
//  Record+Repository.swift
//  Dependn
//
//  Created by David Miotti on 25/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import CoreData
import CocoaLumberjack
import CoreLocation

private let R: Double = 6371009000

extension Record {
    
    class func insertNewRecord(addiction: Addiction,
                               intensity: Float,
                               feeling: String?,
                               comment: String?,
                               place: Place?,
                               latitude: Double?,
                               longitude: Double?,
                               desire: Bool,
                               date: NSDate = NSDate(),
                               inContext context: NSManagedObjectContext) -> Record {
        let record = NSEntityDescription
            .insertNewObjectForEntityForName(Record.entityName,
                                             inManagedObjectContext: context) as! Record
        record.intensity = intensity
        if let addiction = context.objectWithID(addiction.objectID) as? Addiction {
            record.addiction = addiction
        } else {
            record.addiction = addiction
        }
        record.feeling = feeling
        record.comment = comment
        record.place = place
        record.lat = latitude
        record.lon = longitude
        record.date = date
        record.desire = desire
        return record
    }
    
    class func historyFetchedResultsController(inContext context: NSManagedObjectContext) -> NSFetchedResultsController {
        let req = entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        let controller = NSFetchedResultsController(fetchRequest: req,
                                                    managedObjectContext: context,
                                                    sectionNameKeyPath: "sectionIdentifier",
                                                    cacheName: nil)
        return controller
    }
    
    class func deleteRecord(record: Record, inContext context: NSManagedObjectContext) {
        context.deleteObject(record)
    }
    
    class func recordForAddiction(addiction: Addiction, inContext context: NSManagedObjectContext) throws -> [Record] {
        let req = Record.entityFetchRequest()
        req.predicate = NSPredicate(format: "addiction == %@", addiction)
        return try context.executeFetchRequest(req) as? [Record] ?? []
    }
    
    class func recordWithPlace(place: Place, inContext context: NSManagedObjectContext) -> [Record] {
        let req = entityFetchRequest()
        req.predicate = NSPredicate(format: "place == %@", place)
        do {
            return try context.executeFetchRequest(req) as! [Record]
        } catch let err as NSError {
            DDLogError("Error while fetching record with place: \(place): \(err)")
        }
        return []
    }
    
    class func hasAtLeastOneRecord(inContext context: NSManagedObjectContext) -> Bool {
        return recordCount(inContext: context) > 0
    }
    
    class func recordCount(inContext context: NSManagedObjectContext) -> Int {
        let req = entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        
        var error: NSError?
        let count = context.countForFetchRequest(req, error: &error)
        if let err = error {
            DDLogError("Error while counting records: \(err)")
        }
        
        return count
    }

    class func countInRange(addiction: Addiction, start: NSDate, end: NSDate, isDesire: Bool, inContext context: NSManagedObjectContext) -> Int {
        let req = entityFetchRequest()
        req.predicate = NSPredicate(format: "addiction == %@ AND date >= %@ AND date <= %@ AND desire == %@", addiction, start, end, isDesire)

        var error: NSError?
        let count = context.countForFetchRequest(req, error: &error)
        if let err = error {
            DDLogError("Error while counting records in range (\(start), \(end)): \(err)")
        }
        
        return count
    }
    
}