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
import UserNotifications
import UserNotificationsUI

/// Schedule the next push
/// This push should be sent
// 1. Verify the push are accepted
// 2. Get count per addiction for the current day
// 3. Schedule a push
final class PushSchedulerOperation: SHOperation {

    static func schedule(_ completion: ((Void) -> Void)? = nil) {
        let queue = OperationQueue()
        let context = CoreDataStack.shared.managedObjectContext
        let op = PushSchedulerOperation(context: context)
        if let completion = completion {
            let completeOp = BlockOperation {
                completion()
            }

            completeOp.addDependency(op)
            queue.addOperation(completeOp)
        }
        queue.addOperation(op)
    }

    fileprivate(set) var error: NSError?

    fileprivate let context: NSManagedObjectContext
    fileprivate let dateFormatter: DateFormatter

    init(context: NSManagedObjectContext) {
        self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.context.parent = context
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
    }

    override func execute() {
        // 1. Verify the push are accepted
        guard isPushAccepted() else {
            finish()
            return
        }

        // Cancel all others local notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // 2. Get count per addiction for the current day
        context.performAndWait {
            do {
                let addictions = try Addiction.getAllAddictions(inContext: self.context)

                // If we don't have any addictions
                guard addictions.count > 0 else {
                    return
                }

                let rawValue = Defaults[.notificationTypes]
                let types = NotificationTypes(rawValue: rawValue)
                let now = Date()

                if types.contains(.daily) {
                    var obfuscatedAddictions = [String]()

                    // 3. Prepare daily push
                    let fireDate: Date
                    if now.hour < 8 {
                        fireDate = now.beginningOfDay + 8.hour + 1.minute
                    } else {
                        fireDate = now.beginningOfDay + 1.day + 8.hour + 1.minute
                    }

                    let dayBefore = fireDate - 1.day

                    var pushStrings = [String]()
                    for addiction in addictions {
                        if let countInRange = try? Record.countInRange(addiction, start: dayBefore.beginningOfDay, end: dayBefore.endOfDay, isDesire: false, inContext: self.context) {
                            let name = addiction.name
                            let obsfuscated = name.substring(to: name.characters.index(name.startIndex, offsetBy: 3))
                            pushStrings.append("\(obsfuscated). \(countInRange)")
                            obfuscatedAddictions.append(obsfuscated)
                        }
                    }

                    let title = L("daily.push.title")
                    let body = pushStrings.joined(separator: ", ")
                    self.scheduleNotification(at: fireDate, body: "\(title): \(body)")

                    /// schedule an empty push for next days
                    1.month.inDays.toInt.each { i in
                        let nextDate = (fireDate + i.days).beginningOfDay + 8.hour + 1.minute
                        let textes = obfuscatedAddictions.map {
                            return "\($0). 0"
                        }
                        let body = textes.joined(separator: ", ")
                        self.scheduleNotification(at: nextDate, body: "\(title): \(body)")
                    }
                }

                if types.contains(.weekly) {
                    // 4. Schedule de weekly push
                    let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
                    if let comps = (calendar as NSCalendar?)?.components([.year, .month, .weekOfYear, .weekday], from: now) {
                        let weekday = comps.weekday
                        let daysToMonday = (9 - weekday!) % 7
                        var nextMonday = now.addingTimeInterval(60*60*24*daysToMonday).beginningOfDay
                        if nextMonday.timeIntervalSinceNow < 0 {
                            nextMonday = nextMonday + 7.days
                        }
                        let previousMonday = nextMonday - 7.days
                        var pushStrings = [String]()

                        for addiction in addictions {
                            if let countInRange = try? Record.countInRange(addiction, start: previousMonday, end: nextMonday, isDesire: false, inContext: self.context) {
                                let name = addiction.name
                                let obsfuscated = name.substring(to: name.characters.index(name.startIndex, offsetBy: 3))
                                pushStrings.append("\(obsfuscated). \(countInRange)")
                            }
                        }

                        let fireDate = nextMonday + 8.hour + 2.minutes
                        let title = L("weekly.push.title")
                        let body = pushStrings.joined(separator: ", ")
                        self.scheduleNotification(at: fireDate, body: "\(title): \(body)")
                    }
                }
            } catch let err as NSError {
                self.error = err
            }
        }

        finish()
    }
    
    fileprivate func scheduleNotification(at date: Date, body: String) {
        let content = UNMutableNotificationContent()
        content.title = "Dependn'"
        content.body = body
        content.sound = UNNotificationSound.default()
        let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    fileprivate func isPushAccepted() -> Bool {
        let userSettings = UIApplication.shared.currentUserNotificationSettings
        guard let settings = userSettings, settings.types.contains(.alert) else {
            return false
        }
        return true
    }
}
