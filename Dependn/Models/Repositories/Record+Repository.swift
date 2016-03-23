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
                               date: NSDate = NSDate(),
                               inContext context: NSManagedObjectContext) -> Record {
        let record = NSEntityDescription
            .insertNewObjectForEntityForName(Record.entityName,
                                             inManagedObjectContext: context) as! Record
        record.intensity = intensity
        record.addiction = addiction
        record.feeling = feeling
        record.comment = comment
        record.place = place
        record.lat = latitude
        record.lon = longitude
        record.date = date
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
        let controller = NSFetchedResultsController(fetchRequest: req,
                                                    managedObjectContext: context,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        do {
            try controller.performFetch()
            if let records = controller.fetchedObjects as? [Record] {
                return records
            }
        } catch let err as NSError {
            DDLogError("Error while fetching record with place: \(place): \(err)")
        }
        
        return []
    }
    
}