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

final class AverageTimeInBetweenTwoTakesOperation: SHOperation {
    
    private(set) var average: NSTimeInterval?
    private(set) var error: NSError?
    
    private let context: NSManagedObjectContext
    
    override init() {
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
    }
    
    override func execute() {
        let req = NSFetchRequest(entityName: Smoke.entityName)
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        
        context.performBlockAndWait {
            do {
                let results = try self.context.executeFetchRequest(req) as! [Smoke]
                var values = [NSTimeInterval]()
                var lastDate: NSDate?
                for result in results {
                    if let last = lastDate {
                        let interval = last.timeIntervalSinceDate(result.date)
                        values.append(interval)
                    }
                    lastDate = result.date
                }
                self.average = values.reduce(NSTimeInterval(0), combine: +) / NSTimeInterval(values.count)
            } catch let err as NSError {
                self.error = err
            }
        }
        
        finish()
    }

}
