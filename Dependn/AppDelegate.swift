//
//  AppDelegate.swift
//  Dependn
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import SwiftyUserDefaults
import CocoaLumberjack
import SwiftHelpers
import WatchConnectivity
import BrightFutures

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
            }
        }
    }
    
    private let watchQueue = NSOperationQueue()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        Fabric.with([Crashlytics.self])
        StyleSheet.customizeAppearance(window)
        showPasscodeIfNeeded()
        
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
        }
        
        if InitialImportPlacesOperation.shouldImportPlaces() {
            let queue = NSOperationQueue()
            let op = InitialImportPlacesOperation()
            queue.addOperation(op)
        }
        
        prepareDataForAppleWatch()
        
        return true
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        CoreDataStack.shared.saveContext()
        showPasscodeIfNeeded()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        showPasscodeIfNeeded()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        CoreDataStack.shared.saveContext()
    }
    
    // MARK: - Passcode management
    
    private var hidingNav: SHStatusBarNavigationController?
    private var lastPasscodeShown: NSDate?
    
    private func showPasscodeIfNeeded() {
        guard
            hidingNav == nil &&
                PasscodeViewController.supportedOwnerAuthentications().count > 0 &&
                Defaults[.usePasscode] == true else {
                    DDLogInfo("Passcode is already shown or is unsupported")
                    return
        }
        
        if lastPasscodeShown?.timeIntervalSinceDate(NSDate()) < 15 * 60 {
            return
        }
        
        presentPasscode()
    }
    
    private func presentPasscode() {
        if let rootViewController = window?.rootViewController where rootViewController.isViewLoaded() {
            var topController = rootViewController
            while let top = topController.presentedViewController {
                topController = top
            }
            
            lastPasscodeShown = NSDate()
            
            let passcodeViewController = PasscodeViewController()
            hidingNav = SHStatusBarNavigationController(rootViewController: passcodeViewController)
            hidingNav!.statusBarStyle = .LightContent
            hidingNav!.modalTransitionStyle = .CrossDissolve
            topController.presentViewController(hidingNav!, animated: false, completion: nil)
        }
    }
    
}

// MARK: - WCSessionDelegate
extension AppDelegate: WCSessionDelegate {
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        if let action = message["action"] as? String {
            switch action {
            case "get_context":
                prepareDataForAppleWatch().onComplete { r in
                    if let dict = r.value {
                        replyHandler(dict)
                    } else if let err = r.error, sugg = err.localizedRecoverySuggestion {
                        replyHandler([ "error": [
                            "description": err.localizedDescription,
                            "suggestion": sugg
                        ] ])
                    } else {
                        replyHandler([ "error": [
                            "description": L("error.unknown"),
                            "suggestion": L("error.unknown.suggestion")
                        ] ])
                    }
                }
                break
            default:
                break
            }
        }
    }
    
    /// Gather all data from CoreData and format it for reply to Watch
    private func prepareDataForAppleWatch() -> Future<WatchDictionary, NSError> {
        let promise = Promise<WatchDictionary, NSError>()
        
        var replyDict = WatchDictionary()
        
        watchQueue.suspended = true
        
        let statsOp = WatchStatsOperation()
        statsOp.completionBlock = {
            if let result = statsOp.result {
                let res = WatchStatsOperation.formatStatsResultsForAppleWatch(result)
                replyDict["stats"] = res
            } else if let err = statsOp.error, sugg = err.localizedRecoverySuggestion {
                replyDict["error"] = [
                    "description": err.localizedDescription,
                    "suggestion": sugg
                ]
            } else {
                replyDict["error"] = [
                    "description": L("error.unknown"),
                    "suggestion": L("error.unknown.suggestion")
                ]
            }
        }
        watchQueue.addOperation(statsOp)
        
        let newEntryOp = WatchNewEntryInfoOperation()
        newEntryOp.completionBlock = {
            if let result = newEntryOp.watchInfo {
                let res = WatchNewEntryInfoOperation.formatNewEntryResultsForAppleWatch(result)
                replyDict["new_entry"] = res
            } else if let err = newEntryOp.error, sugg = err.localizedRecoverySuggestion {
                replyDict["error"] = [
                    "description": err.localizedDescription,
                    "suggestion": sugg
                ]
            } else {
                replyDict["error"] = [
                    "description": L("error.unknown"),
                    "suggestion": L("error.unknown.suggestion")
                ]
            }
        }
        watchQueue.addOperation(newEntryOp)
        
        let finalBlock = NSBlockOperation {
            promise.success(replyDict)
        }
        finalBlock.addDependency(statsOp)
        finalBlock.addDependency(newEntryOp)
        watchQueue.addOperation(finalBlock)
        
        watchQueue.suspended = false
        
        return promise.future
    }
}
