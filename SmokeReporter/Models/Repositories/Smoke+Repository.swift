//
//  Smoke+Repository.swift
//  SmokeReporter
//
//  Created by David Miotti on 25/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import CoreData

extension Smoke {
    
    static func insertNewSmoke(type: SmokeType,
        intensity: Float,
        before: String?,
        after: String?,
        comment: String?,
        place: Place?,
        date: NSDate = NSDate(),
        inContext context: NSManagedObjectContext = CoreDataStack.shared.managedObjectContext) -> Smoke {
            
            let smoke = NSEntityDescription
                .insertNewObjectForEntityForName(Smoke.entityName,
                    inManagedObjectContext: context) as! Smoke
            smoke.intensity = intensity
            smoke.type = type == .Cigarette ? SmokeTypeCig : SmokeTypeWeed
            smoke.before = before
            smoke.after = after
            smoke.comment = comment
            smoke.place = place
            smoke.date = date
            return smoke
    }
    
    static func historyFetchedResultsController() -> NSFetchedResultsController {
        let req = NSFetchRequest(entityName: Smoke.entityName)
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        let controller = NSFetchedResultsController(fetchRequest: req,
            managedObjectContext: CoreDataStack.shared.managedObjectContext,
            sectionNameKeyPath: "sectionIdentifier",
            cacheName: nil)
        return controller
    }
    
    static func deleteSmoke(smoke: Smoke) {
        CoreDataStack.shared.managedObjectContext.deleteObject(smoke)
    }
    
}