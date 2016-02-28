//
//  AveragePerDayOperation.swift
//  SmokeReporter
//
//  Created by David Miotti on 28/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData

final class AveragePerDayOperation: SHOperation {
    
    let context: NSManagedObjectContext
    
    var average: Float?
    var error: NSError?
    
    private var fetchedResultsController: NSFetchedResultsController
    
    override init() {
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
        fetchedResultsController = Smoke.historyFetchedResultsController(inContext: context)
    }

    override func execute() {
        
        context.performBlockAndWait {
            do {
                try self.fetchedResultsController.performFetch()
                
                var values = [Float]()
                if let sections = self.fetchedResultsController.sections {
                    for section in sections {
                        values.append(Float(section.numberOfObjects))
                    }
                }
                
                self.average = values.reduce(Float(0), combine: +) / Float(values.count)
            } catch let err as NSError {
                self.error = err
            }
        }
        
        finish()
    }
}
