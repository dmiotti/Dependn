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
    
    class func suggestedPlacesFRC(inContext context: NSManagedObjectContext) -> NSFetchedResultsController {
        let req = entityFetchRequest()
        let pred = NSPredicate(format: "records.@count == 0")
        req.predicate = pred
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        return NSFetchedResultsController(
            fetchRequest: req,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
    }
    
    static func recentPlacesFRC(inContext context: NSManagedObjectContext) -> NSFetchedResultsController {
        let req = entityFetchRequest()
        let pred = NSPredicate(format: "records.@count > 0")
        req.predicate = pred
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: false) ]
        return NSFetchedResultsController(
            fetchRequest: req,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
    }
    
    class func allPlaces(inContext context: NSManagedObjectContext, usingPredicate predicate: NSPredicate? = nil) throws -> [Place] {
        let req = entityFetchRequest()
        req.predicate = predicate
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: false) ]
        return try context.executeFetchRequest(req) as! [Place]
    }
    
    class func getAllPlacesOrderedByCount(inContext context: NSManagedObjectContext) throws -> [Place] {
        let req = entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        var places = try context.executeFetchRequest(req) as! [Place]
        places.sortInPlace { $0.records?.count > $1.records?.count }
        return places
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
    
    static func findByName(name: String, inContext context: NSManagedObjectContext) throws -> Place? {
        let req = entityFetchRequest()
        req.predicate = NSPredicate(format: "name ==[cd] %@", name)
        req.fetchLimit = 1
        return try context.executeFetchRequest(req).first as? Place
    }
    
}