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
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        Fabric.with([Crashlytics.self])
        
        StyleSheet.customizeAppearance(window)
        
        if InitialImportPlacesOperation.shouldImportPlaces() {
            let queue = NSOperationQueue()
            let op = InitialImportPlacesOperation()
            queue.addOperation(op)
        }
        
        WatchSessionManager.sharedManager.startSession()
        WatchSessionManager.sharedManager.updateApplicationContext()
        
        showPasscodeIfNeeded()
        
        return true
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        CoreDataStack.shared.saveContext()
        
        WatchSessionManager.sharedManager.updateApplicationContext()
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

