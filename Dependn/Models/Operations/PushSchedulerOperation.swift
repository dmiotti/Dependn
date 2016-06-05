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

        // 2. Get count per addiction for the current day
        context.performBlockAndWait {
            do {
                let addictions = try Addiction.getAllAddictions(inContext: self.context)

                // If we don't have any addictions
                guard addictions.count > 0 else {
                    return
                }

                var pushStrings = [String]()

                for addiction in addictions {
                    let now = NSDate()
                    let countInRange = Record.countInRange(addiction,
                        start:      now.beginningOfDay,
                        end:        now.endOfDay,
                        isDesire:   false,
                        inContext:  self.context)
                    let name = addiction.name
                    let obsfuscated = name.substringToIndex(name.startIndex.advancedBy(3))
                    pushStrings.append("\(obsfuscated). \(countInRange)")
                }

                let push = String(format: L("push.daily.yesterday"),
                    pushStrings.joinWithSeparator(", "))

                // Cancel all others local notifications
                UIApplication.sharedApplication().cancelAllLocalNotifications()

                let notif = UILocalNotification()
                notif.fireDate = NSDate() + 1.minute//.beginningOfDay + 1.day + 8.hour
                notif.alertTitle = L("daily.push.title")
                notif.alertBody = push
                notif.timeZone = NSTimeZone.localTimeZone()

                // 3. Schedule a push
                UIApplication.sharedApplication().scheduleLocalNotification(notif)

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
