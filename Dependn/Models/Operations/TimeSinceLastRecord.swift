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

    var sinceLast: Date?
    var interval: TimeInterval?
    var error: NSError?
    
    let addiction: Addiction
    let context: NSManagedObjectContext
    
    init(addiction: Addiction) {
        self.addiction = addiction
        self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.context.parent = CoreDataStack.shared.managedObjectContext
    }
    
    override func execute() {
        let req = Record.entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
        req.predicate = NSPredicate(format: "addiction == %@", addiction)
        req.fetchLimit = 1
        context.performAndWait {
            do {
                let records = try self.context.fetch(req) as! [Record]
                if let last = records.last {
                    self.sinceLast = last.date
                    self.interval = fabs(last.date.timeIntervalSince(Date()))
                } else {
                    self.sinceLast = Date()
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
