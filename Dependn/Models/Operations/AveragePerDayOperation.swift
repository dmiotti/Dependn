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
    
    fileprivate(set) var average: Float?
    
    fileprivate(set) var fetchedResultsController: NSFetchedResultsController<Record>!
    
    override init() {
        super.init()
        fetchedResultsController = Record.historyFetchedResultsController(inContext: context)
    }

    override func execute() {
        do {
            try self.fetchedResultsController.performFetch()
            
            var values = [Float]()
            if let sections = self.fetchedResultsController.sections {
                for section in sections {
                    values.append(Float(section.numberOfObjects))
                }
            }
            
            if values.count > 0 {
                self.average = values.reduce(Float(0), +) / Float(values.count)
            }
        } catch let err as NSError {
            DDLogError("Error while calculating average per day: \(err)")
            self.error = err
        }
        finish()
    }
}
