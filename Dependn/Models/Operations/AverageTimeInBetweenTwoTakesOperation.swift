//
//  AverageInBetweenTwoTakesOperation.swift
//  Dependn
//
//  Created by David Miotti on 28/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData
import CocoaLumberjack

struct TimeRange {
    let start: NSDate
    let end: NSDate
}

final class AverageTimeInBetweenTwoTakesOperation: CoreDataOperation {
    
    let addiction: Addiction
    let range: TimeRange
    
    private(set) var average: NSTimeInterval?
    
    init(addiction: Addiction, range: TimeRange) {
        self.addiction = addiction
        self.range = range
    }
    
    override func execute() {
        let req = NSFetchRequest(entityName: Record.entityName)
        let addictionPredicate = NSPredicate(format: "addiction == %@", addiction)
        let rangePredicate = NSPredicate(format: "date >= %@ AND date <= %@", range.start, range.end)
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [addictionPredicate, rangePredicate])
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        
        context.performBlockAndWait {
            do {
                let results = try self.context.executeFetchRequest(req) as! [Record]
                var values = [NSTimeInterval]()
                var lastDate: NSDate?
                for result in results {
                    if let last = lastDate {
                        let interval = last.timeIntervalSinceDate(result.date)
                        values.append(interval)
                    }
                    lastDate = result.date
                }
                if values.count > 0 {
                    self.average = values.reduce(NSTimeInterval(0), combine: +) / NSTimeInterval(values.count)
                }
            } catch let err as NSError {
                DDLogError("Error while calculating average between two takes: \(err)")
                self.error = err
            }
        }
        
        finish()
    }

}
