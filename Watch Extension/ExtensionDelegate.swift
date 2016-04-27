//
//  ExtensionDelegate.swift
//  Watch Extension
//
//  Created by David Miotti on 13/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit

final class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        WatchSessionManager.sharedManager.startSession()
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self,
                       selector: #selector(ExtensionDelegate.contextDidUpdate(_:)),
                       name: kWatchExtensionContextUpdatedNotificationName,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(ExtensionDelegate.contextDidFail(_:)),
                       name: kWatchExtensionContextErrorNotificationName,
                       object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        WatchSessionManager.sharedManager.requestContext()
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }
    
    private func showMainController() {
        WKInterfaceController.reloadRootControllersWithNames([
            "ThreeDaysAgo",
            "TwoDaysAgo",
            "Yesterday",
            "Today"
            ], contexts: nil)
    }
    
    private func showErrorController(error: NSError) {
        var context = [String: String]()
        context["info"] = error.localizedDescription
        if let desc = error.localizedRecoverySuggestion {
            context["desc"] = desc
        }
        WKInterfaceController.reloadRootControllersWithNames([
            "InfoInterfaceController"], contexts: [context])
    }
    
    func contextDidUpdate(notification: NSNotification) {
        if let context = notification.userInfo?["context"] as? AppContext where context.stats != nil {
            showMainController()
        }
    }
    
    func contextDidFail(notification: NSNotification) {
        let isInfo = WKExtension.sharedExtension().rootInterfaceController is InfoInterfaceController
        let error = notification.userInfo?["error"] as? NSError
        if let error = error where !isInfo {
            showErrorController(error)
        }
    }

}
