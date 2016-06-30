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
    private let dateFormatter: NSDateFormatter

    init(context: NSManagedObjectContext) {
        self.context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.context.parentContext = context
        self.dateFormatter = NSDateFormatter()
        self.dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
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
                    var obfuscatedAddictions = [String]()

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

                        obfuscatedAddictions.append(obsfuscated)
                    }

                    // 3. Prepare daily push
                    let fireDate: NSDate
                    if now.hour < 8 {
                        fireDate = now.beginningOfDay + 8.hour + 1.minute
                    } else {
                        fireDate = now.beginningOfDay + 1.day + 8.hour + 1.minute
                    }

                    let title = L("daily.push.title")
                    let body = pushStrings.joinWithSeparator(", ")

                    let n = UILocalNotification()
                    n.fireDate = fireDate
                    n.alertTitle = title
                    n.alertBody = body
                    n.timeZone = NSTimeZone.localTimeZone()
                    UIApplication.sharedApplication().scheduleLocalNotification(n)

                    PushSchedulerOperation.printLocalNotification(n)

                    /// schedule an empty push for next days
                    for i in 1..<29 {
                        let nextDate = (fireDate + i.days).beginningOfDay + 8.hour + 1.minute
                        let textes = obfuscatedAddictions.map {
                            return "\($0). 0"
                        }
                        let body = textes.joinWithSeparator(", ")
                        let n = UILocalNotification()
                        n.fireDate = nextDate
                        n.alertTitle = title
                        n.alertBody = body
                        n.timeZone = NSTimeZone.localTimeZone()
                        UIApplication.sharedApplication().scheduleLocalNotification(n)

                        PushSchedulerOperation.printLocalNotification(n)
                    }
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

                        let fireDate = nextMonday + 8.hour + 2.minutes
                        let title = L("weekly.push.title")
                        let body = pushStrings.joinWithSeparator(", ")

                        let n = UILocalNotification()
                        n.fireDate = fireDate
                        n.alertTitle = title
                        n.alertBody = body
                        n.timeZone = NSTimeZone.localTimeZone()
                        UIApplication.sharedApplication().scheduleLocalNotification(n)

                        PushSchedulerOperation.printLocalNotification(n)
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


    private let debugDateFormatter = NSDateFormatter(dateFormat: "yyyy-MM-dd HH:mm")

    static func printLocalNotification(notification: UILocalNotification) {
        #if DEBUG
        let formatter = NSDateFormatter(dateFormat: "yyyy-MM-dd HH:mm:ss")
        let date = formatter.stringFromDate(notification.fireDate!)
        let title = notification.alertTitle!
        let body = notification.alertBody!

        print("[Dependn'] Scheduling daily push: \n\t\(date)\n\t\(title)\n\t\(body)\n")
        #endif
    }

}
