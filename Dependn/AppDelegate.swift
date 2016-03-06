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
import SwiftHelpers
import SwiftyUserDefaults
import LocalAuthentication
import CocoaLumberjack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        Fabric.with([Crashlytics.self])
        StyleSheet.constomizeAppearance(window)
        showPasscodeIfNeeded()
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        CoreDataStack.shared.saveContext()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        showPasscodeIfNeeded()
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        CoreDataStack.shared.saveContext()
    }
    
    private var hidingNav: UINavigationController?
    private var authContext = LAContext()
    
    private func showPasscodeIfNeeded() {
        guard
            hidingNav == nil &&
            supportedOwnerAuthentications().count > 0 &&
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
                
                let hidingViewController = HidingViewController()
                self.hidingNav = UINavigationController(rootViewController: hidingViewController)
                self.hidingNav!.modalTransitionStyle = .CrossDissolve
                topController.presentViewController(self.hidingNav!, animated: false) { finished in
                    self.launchPasscode()
                }
            }
        }
    }
    
    private func launchPasscode() {
        if let policy = supportedOwnerAuthentications().first {
            authContext.evaluatePolicy(policy, localizedReason: L("passcode.reason")) { success, error in
                if success {
                    self.hidingNav?.dismissViewControllerAnimated(true) {
                        self.hidingNav = nil
                    }
                } else {
                    DDLogError("\(error)")
                }
            }
        }
    }
    
    func passcodeSwitchValueChanged(sender: UISwitch) {
        if let policy = supportedOwnerAuthentications().first {
            authContext.evaluatePolicy(policy,
                localizedReason: L("passcode.reason")) { (success, error) in
                    if success {
                        Defaults[.usePasscode] = sender.on
                    } else {
                        DDLogError("\(error)")
                        sender.setOn(!sender.on, animated: true)
                    }
            }
        } else {
            sender.setOn(!sender.on, animated: true)
        }
    }
    
    private func supportedOwnerAuthentications() -> [LAPolicy] {
        var supportedAuthentications = [LAPolicy]()
        var error: NSError?
        if authContext.canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            supportedAuthentications.append(.DeviceOwnerAuthenticationWithBiometrics)
        }
        DDLogError("\(error)")
        if authContext.canEvaluatePolicy(.DeviceOwnerAuthentication, error: &error) {
            supportedAuthentications.append(.DeviceOwnerAuthentication)
        }
        DDLogError("\(error)")
        return supportedAuthentications
    }
    
}

