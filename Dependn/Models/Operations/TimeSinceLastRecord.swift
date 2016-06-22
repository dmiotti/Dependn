//
//  TimeSinceLastRecord.swift
//  Dependn
//
//  Created by David Miotti on 23/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData
import CocoaLumberjack

/// Gets the time in seconds since the last take of an addiction
final class TimeSinceLastRecord: SHOperation {

    var sinceLast: NSDate?
    var interval: NSTimeInterval?
    var error: NSError?
    
    let addiction: Addiction
    let context: NSManagedObjectContext
    
    init(addiction: Addiction) {
        self.addiction = addiction
        self.context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.context.parentContext = CoreDataStack.shared.managedObjectContext
    }
    
    override func execute() {
        let req = Record.entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        req.predicate = NSPredicate(format: "addiction == %@", addiction)
        req.fetchLimit = 1
        context.performBlockAndWait {
            do {
                let records = try self.context.executeFetchRequest(req) as! [Record]
                if let last = records.last {
                    self.sinceLast = last.date
                    self.interval = fabs(last.date.timeIntervalSinceDate(NSDate()))
                } else {
                    self.interval = 0
                }
            } catch let err as NSError {
                DDLogError("Error while fetching last Record: \(err)")
                self.error = err
            }
        }
        finish()
    }

}
