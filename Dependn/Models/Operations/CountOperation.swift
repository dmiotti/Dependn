//
//  CountOperation.swift
//  Dependn
//
//  Created by David Miotti on 24/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData
import CocoaLumberjack

final class CountOperation: SHOperation {
    
    let addiction: Addiction
    let range: TimeRange
    
    private(set) var total: Int?
    private(set) var error: NSError?
    
    private let context: NSManagedObjectContext
    
    init(addiction: Addiction, range: TimeRange) {
        self.addiction = addiction
        self.range = range
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
    }
    
    override func execute() {
        let req = Record.entityFetchRequest()
        let addictionPredicate = NSPredicate(format: "addiction == %@", addiction)
        let rangePredicate = NSPredicate(format: "date >= %@ AND date <= %@", range.start, range.end)
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [addictionPredicate, rangePredicate])
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        
        context.performBlockAndWait {
            do {
                self.total = try self.countForRequest(req)
            } catch let err as NSError {
                DDLogError("Error while counting \(self.addiction.name): \(err)")
                self.error = err
            }
        }
        finish()
    }
    
    private func countForRequest(req: NSFetchRequest) throws -> Int {
        var countErr: NSError?
        let count = context.countForFetchRequest(req, error: &countErr)
        if let err = countErr {
            throw err
        }
        return count
    }

}
