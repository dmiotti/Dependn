//
//  Smoke.swift
//  SmokeReporter
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import CoreData

enum SmokeKind {
    case Cigarette, Weed
}

let kSmokeKindCigarette = "Cigarette"
let kSmokeKindWeed = "Joint"

final class Smoke: NSManagedObject, NamedEntity {
    
    static let sectionDateFormatter = NSDateFormatter(dateFormat: "EEEE dd MMMM yyyy")
    
    static var entityName: String { get { return "Smoke" } }
    
    static func historyFetchedResultsController() -> NSFetchedResultsController {
        let req = NSFetchRequest(entityName: Smoke.entityName)
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        let controller = NSFetchedResultsController(fetchRequest: req,
            managedObjectContext: CoreDataStack.shared.managedObjectContext,
            sectionNameKeyPath: "sectionIdentifier",
            cacheName: nil)
        return controller
    }
    
    static func insertNewSmoke(kind: SmokeKind, intensity: Float, feelingBefore: String?, feelingAfter: String?, comment: String?, date: NSDate = NSDate()) -> Smoke {
        let smoke = NSEntityDescription.insertNewObjectForEntityForName(Smoke.entityName, inManagedObjectContext: CoreDataStack.shared.managedObjectContext) as! Smoke
        smoke.intensity = intensity
        smoke.kind = kind == .Cigarette ? kSmokeKindCigarette : kSmokeKindWeed
        smoke.feelingBefore = feelingBefore
        smoke.feelingAfter = feelingAfter
        smoke.date = date
        smoke.comment = comment
        return smoke
    }
    
    static func deleteSmoke(smoke: Smoke) {
        CoreDataStack.shared.managedObjectContext.deleteObject(smoke)
    }
    
    var normalizedKind: SmokeKind {
        get {
            return kind == kSmokeKindCigarette ? .Cigarette : .Weed
        }
        set {
            if newValue == .Cigarette {
                kind = kSmokeKindCigarette
            } else {
                kind = kSmokeKindWeed
            }
        }
    }
    
    var sectionIdentifier: String? {
        return Smoke.sectionDateFormatter.stringFromDate(date)
    }
    
    
}
