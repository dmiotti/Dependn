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
typealias WatchStatsValueTime = (value: String, date: String)

final class WatchStatsAddiction {
    var addiction = ""
    var values = [WatchStatsValueTime]()
    var sinceLast: NSTimeInterval = 0
}

private let kWatchStatsOperationErrorDomain = "WatchStatsOperation"
private let kWatchStatsOperationNoAddictionErrorCode = 1

final class WatchStatsOperation: CoreDataOperation {
    
    var result: WatchStatsAddiction?
    
    override func execute() {
        
        getAddiction().onComplete { r in
            if let err = r.error {
                self.error = err
                self.finish()
            } else {
                let addiction = r.value!

                let statsAddiction = WatchStatsAddiction()
                statsAddiction.addiction = addiction.name
                
                self.getSinceLast(addiction).onComplete { r in
                    
                    if let sinceLast = r.value {
                        statsAddiction.sinceLast = sinceLast
                    }
                    
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
                            let dateFormatter = NSDateFormatter()
                            dateFormatter.dateFormat = "EE d MMM"
                            
                            let dateFormatted: String
                            
                            let proximity = SHDateProximityToDate(start)
                            switch proximity {
                            case .Today:
                                dateFormatted = L("watch.today")
                            case .Yesterday:
                                dateFormatted = L("watch.yesterday")
                            case .TwoDaysAgo:
                                dateFormatted = L("watch.twoDaysAgo")
                            default:
                                dateFormatted = dateFormatter.stringFromDate(start).capitalizedString
                                break
                            }
                            statsAddiction.values.append((String(count), dateFormatted))
                        }
                    }
                    
                    self.result = statsAddiction
                    
                    self.finish()
                }
            }
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
    
    private func getSinceLast(addiction: Addiction) -> Future<NSTimeInterval, NSError> {
        let promise = Promise<NSTimeInterval, NSError>()
        let queue = NSOperationQueue()
        
        let op = TimeSinceLastRecord(addiction: addiction)
        queue.addOperation(op)
        
        op.completionBlock = {
            if let interval = op.interval {
                promise.success(interval)
            } else {
                promise.failure(op.error!)
            }
        }
        
        return promise.future
    }
    
    static func formatStatsResultsForAppleWatch(result: WatchStatsAddiction) -> WatchDictionary {
        var dict = WatchDictionary()
        dict["name"] = result.addiction
        dict["value"] = result.values.map { [$0.value, $0.date] }
        if result.sinceLast > 0 {
            dict["sinceLast"] = result.sinceLast
        }
        return dict
    }

}
