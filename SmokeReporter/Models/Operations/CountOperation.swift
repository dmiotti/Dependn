//
//  CountOperation.swift
//  SmokeReporter
//
//  Created by David Miotti on 24/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData

final class CountOperation: SHOperation {
    
    var cigaretteCount: Int?
    var weedCount: Int?
    var total: Int?
    var error: NSError?
    
    let context: NSManagedObjectContext
    
    override init() {
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
    }
    
    override func execute() {
        context.performBlockAndWait {
            let cigReq = self.fetchRequestForKind(SmokeTypeCig)
            let weedReq = self.fetchRequestForKind(SmokeTypeWeed)
            do {
                let cigCount = try self.countForRequest(cigReq)
                let weedCount = try self.countForRequest(weedReq)
                self.cigaretteCount = cigCount
                self.weedCount = weedCount
                self.total = cigCount + weedCount
            } catch let err as NSError {
                self.error = err
            }
        }
        finish()
    }
    
    private func fetchRequestForKind(kind: String) -> NSFetchRequest {
        let req = NSFetchRequest(entityName: Smoke.entityName)
        req.predicate = NSPredicate(format: "type == %@", kind)
        return req
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
