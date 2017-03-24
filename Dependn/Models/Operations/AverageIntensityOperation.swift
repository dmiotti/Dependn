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
import CocoaLumberjack

final class AverageIntensityOperation: CoreDataOperation {
    
    fileprivate(set) var average: Float?
    
    override func execute() {
        
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: Record.entityName)
        req.resultType = .dictionaryResultType
        let exp = NSExpression(forKeyPath: "intensity")
        
        let expDesc = NSExpressionDescription()
        expDesc.expression = exp
        expDesc.name = "averageIntensity"
        expDesc.expressionResultType = .floatAttributeType
        
        req.propertiesToFetch = [ expDesc ]
        
        context.performAndWait {
            do {
                let objects = try self.context.fetch(req)
                if let obj = objects.first as? NSObject, let avg = obj.value(forKey: "averageIntensity") as? NSNumber {
                    self.average = avg.floatValue
                }
            } catch let err as NSError {
                DDLogError("Error while calculating average intensity: \(err)")
                self.error = err
            }
        }
        
        finish()
    }

}
