//
//  WatchStatsOperation.swift
//  Dependn
//
//  Created by David Miotti on 25/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import SwiftHelpers
import CoreData

typealias WatchDictionary = Dictionary<String, AnyObject>
typealias WatchStatsValueTime = (value: String, date: NSDate)

class WatchStatsAddiction {
    var addiction = ""
    var values = [WatchStatsValueTime]()
}

final class WatchStatsOperation: SHOperation {
    
    var results = [WatchStatsAddiction]()
    var error: NSError?
    
    private let context: NSManagedObjectContext
    
    override init() {
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
    }
    
    override func execute() {
        
        do {
            let addictions = try Addiction.getAllAddictions(inContext: self.context)
            
            for addiction in addictions {
                
                let statsAddiction = WatchStatsAddiction()
                statsAddiction.addiction = addiction.name
                
                let now = NSDate()
                let req = NSFetchRequest(entityName: Record.entityName)
                
                for i in 0...3 {
                    let date = now - i.days
                    let start = date.beginningOfDay
                    let end = date.endOfDay
                    
                    let rangepre = NSPredicate(format: "date >= %@ AND date <= %@", start, end)
                    let addicpred = NSPredicate(format: "addiction == %@", addiction)
                    req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [rangepre, addicpred])
                    
                    var error: NSError?
                    let count = self.context.countForFetchRequest(req, error: &error)
                    if let err = error {
                        throw err
                    }
                    
                    statsAddiction.values.append(("\(count)", start))
                }
                
                self.results.append(statsAddiction)
            }
        } catch let err as NSError {
            self.error = err
        }
        
        finish()
    }
    
    static func formatStatsResultsForAppleWatch(results: [WatchStatsAddiction]) -> [WatchDictionary] {
        var data = [WatchDictionary]()
        for result in results {
            var addiction = WatchDictionary()
            addiction["name"] = result.addiction
            addiction["value"] = result.values.map({ [$0.value, $0.date] })
            data.append(addiction)
        }
        return data
    }

}
