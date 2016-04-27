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
        
        return true
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        CoreDataStack.shared.saveContext()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        showPasscodeIfNeeded()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        CoreDataStack.shared.saveContext()
    }
    
    // MARK: - Passcode management
    
    private var hidingNav: SHStatusBarNavigationController?
    
    private func showPasscodeIfNeeded() {
        guard
            hidingNav == nil &&
                PasscodeViewController.supportedOwnerAuthentications().count > 0 &&
                Defaults[.usePasscode] == true else {
                    DDLogInfo("Passcode is already shown or is unsupported")
                    return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            if let rootViewController = self.window?.rootViewController where rootViewController.isViewLoaded() {
                var topController = rootViewController
                while let top = topController.presentedViewController {
                    topController = top
                }
                
                let passcodeViewController = PasscodeViewController()
                self.hidingNav = SHStatusBarNavigationController(rootViewController: passcodeViewController)
                self.hidingNav!.statusBarStyle = .LightContent
                self.hidingNav!.modalTransitionStyle = .CrossDissolve
                topController.presentViewController(self.hidingNav!, animated: false, completion: nil)
            }
        }
    }
    
}

// MARK: - WCSessionDelegate
extension AppDelegate: WCSessionDelegate {
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        if let action = message["action"] as? String {
            switch action {
            case "stats":
                let statsOp = WatchStatsOperation()
                statsOp.completionBlock = {
                    if let result = statsOp.result {
                        let res = WatchStatsOperation.formatStatsResultsForAppleWatch(result)
                        replyHandler([ "stats": res ])
                    } else if let err = statsOp.error, sugg = err.localizedRecoverySuggestion {
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
                watchQueue.addOperation(statsOp)
                break
            default:
                break
            }
        }
    }
}
