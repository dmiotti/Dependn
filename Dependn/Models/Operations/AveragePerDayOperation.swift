//
//  AveragePerDayOperation.swift
//  Dependn
//
//  Created by David Miotti on 28/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData

final class AveragePerDayOperation: SHOperation {
    
    private(set) var average: Float?
    private(set) var error: NSError?
    
    private let context: NSManagedObjectContext
    private(set) var fetchedResultsController: NSFetchedResultsController
    
    override init() {
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
        fetchedResultsController = Record.historyFetchedResultsController(inContext: context)
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
                
                if values.count > 0 {
                    self.average = values.reduce(Float(0), combine: +) / Float(values.count)
                }
            } catch let err as NSError {
                self.error = err
            }
        }
        
        finish()
    }
}
