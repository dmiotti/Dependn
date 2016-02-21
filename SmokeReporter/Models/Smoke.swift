//
//  Smoke.swift
//  SmokeReporter
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import CoreData

final class Smoke: NSManagedObject {
    static let entityName = "Smoke"
    
    static func historyFetchedResultsController() -> NSFetchedResultsController {
        let req = NSFetchRequest(entityName: Smoke.entityName)
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: true) ]
        let controller = NSFetchedResultsController(fetchRequest: req,
            managedObjectContext: CoreDataStack.shared.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return controller
    }
}
