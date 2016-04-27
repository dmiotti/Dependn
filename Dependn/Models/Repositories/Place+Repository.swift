//
//  Place+Repository.swift
//  Dependn
//
//  Created by David Miotti on 22/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import CoreData
import CocoaLumberjack

extension Place {
    
    class func placesFetchedResultsController(inContext context: NSManagedObjectContext) -> NSFetchedResultsController {
        let req = entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        let controller = NSFetchedResultsController(
            fetchRequest: req,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return controller
    }
    
    class func allPlaces(inContext context: NSManagedObjectContext, usingPredicate predicate: NSPredicate? = nil) throws -> [Place] {
        let req = entityFetchRequest()
        req.predicate = predicate
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: false) ]
        return try context.executeFetchRequest(req) as! [Place]
    }
    
    class func insertPlace(name: String, inContext context: NSManagedObjectContext) -> Place {
        let place = Place.insertEntity(inContext: context)
        place.name = name
        return place
    }
    
    class func deletePlace(place: Place, inContext context: NSManagedObjectContext) {
        let records = Record.recordWithPlace(place, inContext: context)
        for record in records {
            record.place = nil
        }
        context.deleteObject(place)
    }
    
}