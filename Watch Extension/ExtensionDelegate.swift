//
//  ExtensionDelegate.swift
//  Watch Extension
//
//  Created by David Miotti on 13/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit

let kWatchExtensionStatsUpdatedNotificationName = "kWatchExtensionStatsUpdated"
let kWatchExtensionStatsErrorNotificationName = "kWatchExtensionError"

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        CoreStack.shared.getContext { context, err in
            if let stats = context?.stats {
                NSNotificationCenter.defaultCenter().postNotificationName(
                    kWatchExtensionStatsUpdatedNotificationName,
                    object: nil, userInfo: ["stats": stats])
            } else if let err = err {
                NSNotificationCenter.defaultCenter().postNotificationName(
                    kWatchExtensionStatsErrorNotificationName,
                    object: nil, userInfo: [ "error": err ])
            } else {
                let err = NSError(domain: "Dependn Watch App", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Unknown Error",
                    NSLocalizedRecoverySuggestionErrorKey: "Please restart"
                    ])
                NSNotificationCenter.defaultCenter().postNotificationName(
                    kWatchExtensionStatsErrorNotificationName,
                    object: nil, userInfo: [ "error": err ])
            }
        }
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

}
