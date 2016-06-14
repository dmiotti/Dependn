//
//  PushSchedulerOperation.swift
//  Dependn
//
//  Created by David Miotti on 05/06/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData
import SwiftyUserDefaults

/// Schedule the next push
/// This push should be sent
// 1. Verify the push are accepted
// 2. Get count per addiction for the current day
// 3. Schedule a push
final class PushSchedulerOperation: SHOperation {

    static func schedule(completion: (Void -> Void)? = nil) {
        let queue = NSOperationQueue()
        let context = CoreDataStack.shared.managedObjectContext
        let op = PushSchedulerOperation(context: context)
        if let completion = completion {
            let completeOp = NSBlockOperation {
                completion()
            }

            completeOp.addDependency(op)
            queue.addOperation(completeOp)
        }
        queue.addOperation(op)
    }

    private(set) var error: NSError?

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.context.parentContext = context
    }

    override func execute() {
        // 1. Verify the push are accepted
        guard isPushAccepted() else {
            finish()
            return
        }

        // Cancel all others local notifications
        UIApplication.sharedApplication().cancelAllLocalNotifications()

        // 2. Get count per addiction for the current day
        context.performBlockAndWait {
            do {
                let addictions = try Addiction.getAllAddictions(inContext: self.context)

                // If we don't have any addictions
                guard addictions.count > 0 else {
                    return
                }

                let rawValue = Defaults[.notificationTypes]
                let types = NotificationTypes(rawValue: rawValue)
                let now = NSDate()

                if types.contains(.Daily) {
                    var pushStrings = [String]()
                    for addiction in addictions {
                        let countInRange = Record.countInRange(addiction,
                            start:      now.beginningOfDay,
                            end:        now.endOfDay,
                            isDesire:   false,
                            inContext:  self.context)
                        let name = addiction.name
                        let obsfuscated = name.substringToIndex(name.startIndex.advancedBy(3))
                        pushStrings.append("\(obsfuscated). \(countInRange)")
                    }

                    // 3. Prepare daily push
                    let daily = UILocalNotification()
                    daily.fireDate = now.beginningOfDay + 1.day + 8.hour
                    daily.alertTitle = L("daily.push.title")
                    daily.alertBody = pushStrings.joinWithSeparator(", ")
                    daily.timeZone = NSTimeZone.localTimeZone()
                    UIApplication.sharedApplication().scheduleLocalNotification(daily)
                }

                if types.contains(.Weekly) {
                    // 4. Schedule de weekly push
                    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
                    if let comps = calendar?.components([.Year, .Month, .WeekOfYear, .Weekday], fromDate: now) {
                        let weekday = comps.weekday
                        let daysToMonday = (9 - weekday) % 7
                        var nextMonday = now.dateByAddingTimeInterval(60*60*24*daysToMonday).beginningOfDay
                        if nextMonday.timeIntervalSinceNow < 0 {
                            nextMonday = nextMonday + 7.days
                        }
                        let previousMonday = nextMonday - 7.days
                        var pushStrings = [String]()

                        for addiction in addictions {
                            let countInRange = Record.countInRange(addiction,
                                start:      previousMonday,
                                end:        nextMonday,
                                isDesire:   false,
                                inContext:  self.context)
                            let name = addiction.name
                            let obsfuscated = name.substringToIndex(name.startIndex.advancedBy(3))
                            pushStrings.append("\(obsfuscated). \(countInRange)")
                        }

                        let weekly = UILocalNotification()
                        weekly.fireDate = nextMonday + 8.hour
                        weekly.alertTitle = L("daily.push.title")
                        weekly.alertBody = pushStrings.joinWithSeparator(", ")
                        weekly.timeZone = NSTimeZone.localTimeZone()
                        UIApplication.sharedApplication().scheduleLocalNotification(weekly)
                    }
                }
            } catch let err as NSError {
                self.error = err
            }
        }

        finish()
    }

    private func isPushAccepted() -> Bool {
        let userSettings = UIApplication.sharedApplication().currentUserNotificationSettings()
        guard let settings = userSettings where settings.types.contains(.Alert) else {
            return false
        }
        return true
    }

}
