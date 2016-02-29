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
    
    static func insertNewRecord(type: RecordType,
        intensity: Float,
        before: String?,
        after: String?,
        comment: String?,
        place: String?,
        latitude: Double?,
        longitude: Double?,
        date: NSDate = NSDate(),
        inContext context: NSManagedObjectContext) -> Record {
            let record = NSEntityDescription
                .insertNewObjectForEntityForName(Record.entityName,
                    inManagedObjectContext: context) as! Record
            record.intensity = intensity
            record.type = type == .Cig ? kRecordTypeCig : kRecordTypeWeed
            record.before = before
            record.after = after
            record.comment = comment
            record.place = place
            record.lat = latitude
            record.lon = longitude
            record.date = date
            return record
    }
    
    static func historyFetchedResultsController(inContext context: NSManagedObjectContext) -> NSFetchedResultsController {
        let req = NSFetchRequest(entityName: Record.entityName)
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        let controller = NSFetchedResultsController(fetchRequest: req,
            managedObjectContext: context,
            sectionNameKeyPath: "sectionIdentifier",
            cacheName: nil)
        return controller
    }
    
    static func deleteRecord(record: Record) {
        CoreDataStack.shared.managedObjectContext.deleteObject(record)
    }
    
}