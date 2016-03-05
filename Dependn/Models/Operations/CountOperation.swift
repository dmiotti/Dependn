//
//  CountOperation.swift
//  Dependn
//
//  Created by David Miotti on 24/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData

final class CountOperation: SHOperation {
    
    private(set) var total: Int?
    private(set) var error: NSError?
    
    private let context: NSManagedObjectContext
    
    override init() {
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
    }
    
    override func execute() {
        context.performBlockAndWait {
            let req = Record.entityFetchRequest()
            do {
                self.total = try self.countForRequest(req)
            } catch let err as NSError {
                self.error = err
            }
        }
        finish()
    }
    
    private func countForRequest(req: NSFetchRequest) throws -> Int {
        var countErr: NSError?
        let count = context.countForFetchRequest(req, error: &countErr)
        if let err = countErr {
            throw err
        }
        return count
    }

}
