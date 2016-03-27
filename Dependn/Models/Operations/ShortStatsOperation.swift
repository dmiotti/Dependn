//
//  ShortStatsOperation.swift
//  Dependn
//
//  Created by David Miotti on 27/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData

class StatsResult {
    var addiction: String
    var todayCount: Int?
    var thisWeekCount: Int?
    var sinceLast: NSTimeInterval?
    
    init(addiction: String) {
        self.addiction = addiction
    }
}

final class ShortStatsOperation: SHOperation {
    
    var results = [StatsResult]()
    var error: NSError?
    
    private let internalQueue = NSOperationQueue()
    private let context: NSManagedObjectContext
    
    var userAddictions: [Addiction]?
    
    init(addictions: [Addiction]? = nil) {
        userAddictions = addictions
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
    }
    
    override func execute() {
        do {
            let addictions: [Addiction]
            if let adds = userAddictions {
                addictions = adds
            } else {
                addictions = try Addiction.getAllAddictionsOrderedByCount(inContext: context)
            }
            
            internalQueue.suspended = true
            
            var statOperations = [SHOperation]()
            
            for addiction in addictions {
                let operations = setupOperationsForAddiction(addiction)
                statOperations.appendContentsOf(operations)
            }
            
            let finalOp = NSBlockOperation {
                self.finish()
            }
            
            for op in statOperations {
                finalOp.addDependency(op)
            }
            
            internalQueue.addOperation(finalOp)
            
            internalQueue.suspended = false
            
        } catch let err as NSError {
            self.error = err
        }
    }
    
    private func setupOperationsForAddiction(addiction: Addiction) -> [SHOperation] {
        let statsResult = StatsResult(addiction: addiction.name)
        results.append(statsResult)
        
        let now = NSDate()
        
        let todayRange = TimeRange(start: now.beginningOfDay, end: now)
        let todayOp = CountOperation(addiction: addiction, range: todayRange)
        todayOp.completionBlock = {
            if let count = todayOp.total {
                statsResult.todayCount = count
            } else if let err = todayOp.error {
                print(err)
            }
        }
        
        let weekRange = TimeRange(start: now.beginningOfWeek, end: now)
        let weekCountOp = CountOperation(addiction: addiction, range: weekRange)
        weekCountOp.completionBlock = {
            if let count = weekCountOp.total {
                statsResult.thisWeekCount = count
            } else if let err = weekCountOp.error {
                print(err)
            }
        }
        
        let sinceLastOp = TimeSinceLastRecord(addiction: addiction)
        sinceLastOp.completionBlock = {
            if let interval = sinceLastOp.interval {
                statsResult.sinceLast = interval
            } else if let err = sinceLastOp.error {
                print(err)
            }
        }
        
        weekCountOp.addDependency(todayOp)
        sinceLastOp.addDependency(weekCountOp)
        
        internalQueue.addOperation(todayOp)
        internalQueue.addOperation(weekCountOp)
        internalQueue.addOperation(sinceLastOp)
        
        return [ todayOp, weekCountOp, sinceLastOp ]
    }
    
}
