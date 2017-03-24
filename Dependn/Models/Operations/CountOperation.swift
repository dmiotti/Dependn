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

final class CountOperation: CoreDataOperation {
    
    let addiction: Addiction
    let range: TimeRange
    
    fileprivate(set) var total: Int?
    
    init(addiction: Addiction, range: TimeRange) {
        self.addiction = addiction
        self.range = range
    }
    
    override func execute() {
        let req = Record.entityFetchRequest()
        let addictionPredicate = NSPredicate(format: "addiction == %@", addiction)
        let rangePredicate = NSPredicate(format: "date >= %@ AND date <= %@", range.start as NSDate, range.end as NSDate)
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [addictionPredicate, rangePredicate])
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        
        context.performAndWait {
            do {
                self.total = try self.context.count(for: req)
            } catch let err as NSError {
                DDLogError("Error while counting \(self.addiction.name): \(err)")
                self.error = err
            }
        }
        finish()
    }
}
