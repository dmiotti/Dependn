//
//  AverageIntensityOperation.swift
//  Dependn
//
//  Created by David Miotti on 28/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData

final class AverageIntensityOperation: SHOperation {
    
    private(set) var error: NSError?
    private(set) var average: Float = 0
    
    private let context: NSManagedObjectContext
    
    override init() {
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
    }
    
    override func execute() {
        
        let req = NSFetchRequest(entityName: Record.entityName)
        req.resultType = .DictionaryResultType
        let exp = NSExpression(forKeyPath: "intensity")
        
        let expDesc = NSExpressionDescription()
        expDesc.expression = exp
        expDesc.name = "averageIntensity"
        expDesc.expressionResultType = .FloatAttributeType
        
        req.propertiesToFetch = [ expDesc ]
        
        context.performBlockAndWait {
            do {
                let objects = try self.context.executeFetchRequest(req)
                if let obj = objects.first as? NSObject, avg = obj.valueForKey("averageIntensity") as? NSNumber {
                    self.average = avg.floatValue
                }
            } catch let err as NSError {
                self.error = err
            }
        }
        
        finish()
    }

}
