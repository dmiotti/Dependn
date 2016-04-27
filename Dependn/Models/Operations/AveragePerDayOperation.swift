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
import CocoaLumberjack

final class AveragePerDayOperation: CoreDataOperation {
    
    private(set) var average: Float?
    
    private(set) var fetchedResultsController: NSFetchedResultsController!
    
    override init() {
        super.init()
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
                DDLogError("Error while calculating average per day: \(err)")
                self.error = err
            }
        }
        
        finish()
    }
}
