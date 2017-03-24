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
    let start: Date
    let end: Date
}

final class AverageTimeInBetweenTwoTakesOperation: CoreDataOperation {
    
    let addiction: Addiction
    let range: TimeRange
    
    fileprivate(set) var average: TimeInterval?
    
    init(addiction: Addiction, range: TimeRange) {
        self.addiction = addiction
        self.range = range
    }
    
    override func execute() {
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: Record.entityName)
        let addictionPredicate = NSPredicate(format: "addiction == %@", addiction)
        let rangePredicate = NSPredicate(format: "date >= %@ AND date <= %@", range.start as NSDate, range.end as NSDate)
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [addictionPredicate, rangePredicate])
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        
        context.performAndWait {
            do {
                let results = try self.context.fetch(req) as! [Record]
                var values = [TimeInterval]()
                var lastDate: Date?
                for result in results {
                    if let last = lastDate {
                        let interval = last.timeIntervalSince(result.date as Date)
                        values.append(interval)
                    }
                    lastDate = result.date as Date
                }
                if values.count > 0 {
                    self.average = values.reduce(TimeInterval(0), +) / TimeInterval(values.count)
                }
            } catch let err as NSError {
                DDLogError("Error while calculating average between two takes: \(err)")
                self.error = err
            }
        }
        
        finish()
    }

}
