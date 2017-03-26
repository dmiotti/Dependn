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

                    let now = Date()
                    for i in 1..<1.month.inDays.toInt {
                        var comps = Calendar.current.dateComponents([.hour, .minute, .day, .era, .year, .month], from: now)
                        comps.day = (comps.day ?? 0) + i
                        comps.hour = 9
                        comps.minute = 0
                        let nextDate = Calendar.current.date(from: comps)
                        comps.day = (comps.day ?? 0) - 1
                        let dayBefore = Calendar.current.date(from: comps)
                        
                        if let nextDate = nextDate, let dayBefore = dayBefore {
                            var obfuscatedAddictions = [String]()
                            var pushStrings = [String]()
                            for addiction in addictions {
                                let numberOfConso = try? Record.countInRange(addiction, start: dayBefore.beginningOfDay, end: dayBefore.endOfDay, isDesire: false, inContext: self.context)
                                if let numberOfConso = numberOfConso {
                                    let name = addiction.name
                                    let obsfuscated = name.substring(to: name.characters.index(name.startIndex, offsetBy: 3))
                                    pushStrings.append("\(obsfuscated). \(numberOfConso)")
                                    obfuscatedAddictions.append(obsfuscated)
                                }
                            }
                            
                            let body = pushStrings.joined(separator: ", ")
                            self.scheduleNotification(at: nextDate, body: "\(L("daily.push.title")): \(body)")
                        }
                    }
                }

                if types.contains(.weekly) {
                    // 4. Schedule de weekly push
                    let start = now.startOfWeek
                    let end = now.endOfWeek
                    
                    var pushStrings = [String]()
                    for addiction in addictions {
                        if let countInRange = try? Record.countInRange(addiction, start: start, end: end, isDesire: false, inContext: self.context) {
                            let name = addiction.name
                            let obsfuscated = name.substring(to: name.characters.index(name.startIndex, offsetBy: 3))
                            pushStrings.append("\(obsfuscated). \(countInRange)")
                        }
                    }
                    
                    var fireComps = Calendar.current.dateComponents([.hour, .minute, .day, .era, .year, .month], from: end)
                    fireComps.hour = (fireComps.hour ?? 0) + 9
                    fireComps.minute = 2
                    if let fireDate = Calendar.current.date(from: fireComps) {
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
        UNUserNotificationCenter.current().add(request)
    }

    fileprivate func isPushAccepted() -> Bool {
        let userSettings = UIApplication.shared.currentUserNotificationSettings
        guard let settings = userSettings, settings.types.contains(.alert) else {
            return false
        }
        return true
    }
}
