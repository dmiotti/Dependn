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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


extension Place {
    
    class func suggestedPlacesFRC(inContext context: NSManagedObjectContext, forSearch search: String? = nil) -> NSFetchedResultsController<Place> {
        let req = Place.entityFetchRequest()
        let pred = NSPredicate(format: "records.@count == 0")
        if let search = search {
            let filter = NSPredicate(format: "name contains[cd] %@", search)
            req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [pred, filter])
        } else {
            req.predicate = pred
        }
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        return NSFetchedResultsController<Place>(
            fetchRequest: req,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
    }
    
    static func recentPlacesFRC(inContext context: NSManagedObjectContext, forSearch search: String? = nil) -> NSFetchedResultsController<Place> {
        let req = Place.entityFetchRequest()
        let pred = NSPredicate(format: "records.@count > 0")
        if let search = search {
            let filter = NSPredicate(format: "name contains[cd] %@", search)
            req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [pred, filter])
        } else {
            req.predicate = pred
        }
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
        return try context.fetch(req)
    }
    
    class func getAllPlacesOrderedByCount(inContext context: NSManagedObjectContext) throws -> [Place] {
        let req = entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        var places = try context.fetch(req)
        places.sort { $0.records?.count > $1.records?.count }
        return places
    }
    
    class func insertPlace(_ name: String, inContext context: NSManagedObjectContext) -> Place {
        let place = Place.insertEntity(inContext: context)
        place.name = name
        return place
    }
    
    class func deletePlace(_ place: Place, inContext context: NSManagedObjectContext) {
        let records = Record.recordWithPlace(place, inContext: context)
        for record in records {
            record.place = nil
        }
        context.delete(place)
    }
    
    static func findByName(_ name: String, inContext context: NSManagedObjectContext) throws -> Place? {
        let req = entityFetchRequest()
        req.predicate = NSPredicate(format: "name ==[cd] %@", name)
        req.fetchLimit = 1
        return try context.fetch(req).first
    }
    
}
