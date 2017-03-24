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

typealias WatchDictionary = Dictionary<String, Any>
typealias WatchStatsValueTime = (value: String, date: String)

final class WatchStatsAddiction {
    var addiction = ""
    var values = [WatchStatsValueTime]()
    var sinceLast: Date!
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
                        statsAddiction.sinceLast = sinceLast as Date!
                    }
                    
                    let now = Date()
                    let req = NSFetchRequest<Record>(entityName: Record.entityName)
                    
                    3.each { i in
                        let date = now - i.days
                        let start = date.beginningOfDay
                        let end = date.endOfDay
                        
                        let rangepre = NSPredicate(format: "date >= %@ AND date <= %@", start as NSDate, end as NSDate)
                        let addicpred = NSPredicate(format: "addiction == %@", addiction)
                        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [rangepre, addicpred])
                        
                        do {
                            let count = try self.context.count(for: req)
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "EE d MMM"
                            let day: String
                            let proximity = SHDateProximityToDate(start)
                            switch proximity {
                            case .today:
                                day = L("watch.today")
                            case .yesterday:
                                day = L("watch.yesterday")
                            case .twoDaysAgo:
                                day = L("watch.twoDaysAgo")
                            default:
                                day = dateFormatter.string(from: start).capitalized
                                break
                            }
                            statsAddiction.values.append((String(count), day))
                        } catch let err as NSError {
                            self.error = err
                        }
                    }
                    
                    self.result = statsAddiction
                    
                    self.finish()
                }
            }
        }
    }
    
    fileprivate func getAddiction() -> Future<Addiction, NSError> {
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
    
    fileprivate func getSinceLast(_ addiction: Addiction) -> Future<Date, NSError> {
        let promise = Promise<Date, NSError>()
        let queue = OperationQueue()
        let op = TimeSinceLastRecord(addiction: addiction)
        queue.addOperation(op)
        op.completionBlock = {
            if let sinceLast = op.sinceLast {
                promise.success(sinceLast)
            } else {
                promise.failure(op.error!)
            }
        }
        return promise.future
    }
    
    static func formatStatsResultsForAppleWatch(_ result: WatchStatsAddiction) -> WatchDictionary {
        var dict = WatchDictionary()
        dict["name"] = result.addiction
        dict["value"] = result.values.map { [$0.value, $0.date] }
        dict["sinceLast"] = result.sinceLast
        return dict
    }

}
