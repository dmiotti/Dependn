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
import SwiftyUserDefaults
import BrightFutures

typealias WatchDictionary = Dictionary<String, AnyObject>
typealias WatchStatsValueTime = (value: String, date: NSDate)

final class WatchStatsAddiction {
    var addiction = ""
    var values = [WatchStatsValueTime]()
}

private let kWatchStatsOperationErrorDomain = "WatchStatsOperation"
private let kWatchStatsOperationNoAddictionErrorCode = 1

final class WatchStatsOperation: CoreDataOperation {
    
    var result: WatchStatsAddiction?
    
    override func execute() {
        
        getAddiction().onComplete { r in
            if let err = r.error {
                self.error = err
            } else {
                let addiction = r.value!

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
                        self.error = err
                    } else {
                        statsAddiction.values.append(("\(count)", start))
                    }
                }
                
                self.result = statsAddiction
            }
            self.finish()
        }
    }
    
    private func getAddiction() -> Future<Addiction, NSError> {
        let promise = Promise<Addiction, NSError>()
        
        do {
            if let addictionName = Defaults[.watchAddiction] {
                if let addiction = try Addiction.findByName(addictionName, inContext: context) {
                    promise.success(addiction)
                } else {
                    promise.failure(NSError(
                        domain: kWatchStatsOperationErrorDomain,
                        code: kWatchStatsOperationNoAddictionErrorCode,
                        userInfo: [
                            NSLocalizedDescriptionKey: L("error.no_addiction"),
                            NSLocalizedRecoverySuggestionErrorKey: L("error.no_addiction.suggestion")
                        ]))
                }
            } else {
                let addictions = try Addiction.getAllAddictionsOrderedByCount(inContext: context)
                if let first = addictions.first {
                    promise.success(first)
                } else {
                    promise.failure(NSError(
                        domain: kWatchStatsOperationErrorDomain,
                        code: kWatchStatsOperationNoAddictionErrorCode,
                        userInfo: [
                            NSLocalizedDescriptionKey: L("error.no_addiction"),
                            NSLocalizedRecoverySuggestionErrorKey: L("error.no_addiction.suggestion")
                        ]))
                }
            }
        } catch let err as NSError {
            promise.failure(err)
        }
        
        return promise.future
    }
    
    static func formatStatsResultsForAppleWatch(result: WatchStatsAddiction) -> WatchDictionary {
        var dict = WatchDictionary()
        dict["name"] = result.addiction
        dict["value"] = result.values.map({ [$0.value, $0.date] })
        return dict
    }

}
