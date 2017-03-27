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
    
    class func insertNewRecord(_ addiction: Addiction,
                               intensity: Float,
                               feeling: String?,
                               comment: String?,
                               place: Place?,
                               latitude: Double?,
                               longitude: Double?,
                               desire: Bool,
                               date: Date = Date(),
                               inContext context: NSManagedObjectContext) -> Record {
        let record = NSEntityDescription
            .insertNewObject(forEntityName: Record.entityName,
                                             into: context) as! Record
        record.intensity = NSNumber(value: intensity)
        if let addiction = context.object(with: addiction.objectID) as? Addiction {
            record.addiction = addiction
        } else {
            record.addiction = addiction
        }
        record.feeling = feeling
        record.comment = comment
        record.place = place
        record.lat = latitude as NSNumber?
        record.lon = longitude as NSNumber?
        record.date = date
        record.desire = desire as NSNumber
        return record
    }
    
    class func historyFetchedResultsController(inContext context: NSManagedObjectContext) -> NSFetchedResultsController<Record> {
        let req = Record.entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        let controller = NSFetchedResultsController<Record>(fetchRequest: req, managedObjectContext: context, sectionNameKeyPath: "sectionIdentifier", cacheName: nil)
        return controller
    }
    
    class func deleteRecord(_ record: Record, inContext context: NSManagedObjectContext) {
        context.delete(record)
    }
    
    class func recordForAddiction(_ addiction: Addiction, inContext context: NSManagedObjectContext) throws -> [Record] {
        let req = Record.entityFetchRequest()
        req.predicate = NSPredicate(format: "addiction == %@", addiction)
        return try context.fetch(req)
    }
    
    class func recordWithPlace(_ place: Place, inContext context: NSManagedObjectContext) -> [Record] {
        let req = entityFetchRequest()
        req.predicate = NSPredicate(format: "place == %@", place)
        do {
            return try context.fetch(req)
        } catch let err as NSError {
            DDLogError("Error while fetching record with place: \(place): \(err)")
        }
        return []
    }
    
    class func hasAtLeastOneRecord(inContext context: NSManagedObjectContext) throws -> Bool {
        return try recordCount(inContext: context) > 0
    }
    
    class func recordCount(inContext context: NSManagedObjectContext) throws -> Int {
        let req = entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        return try context.count(for: req)
    }

    class func countInRange(_ addiction: Addiction, start: Date, end: Date, isDesire: Bool, inContext context: NSManagedObjectContext) throws -> Int {
        let req = entityFetchRequest()
        req.predicate = NSPredicate(format: "addiction == %@ AND date >= %@ AND date <= %@ AND desire == %@", addiction, start as NSDate, end as NSDate, NSNumber(value: isDesire))
        return try context.count(for: req)
    }
}
