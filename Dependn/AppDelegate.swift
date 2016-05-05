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
import Amplitude_iOS

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: Types
    
    enum ShortcutIdentifier: String {
        case Add
        
        // MARK: Initializers
        
        init?(fullType: String) {
            guard let last = fullType.componentsSeparatedByString(".").last else {
                return nil
            }
            
            self.init(rawValue: last)
        }
        
        // MARK: Properties
        
        var type: String {
            return NSBundle.mainBundle().bundleIdentifier! + ".\(self.rawValue)"
        }
    }
    
    // MARK: Static properties
    
    static let applicationShortcutUserInfoIconKey = "applicationShortcutUserInfoIconKey"
    
    // MARK: Properties
    
    var window: UIWindow?
    
    /// Saved shortcut item used as a result of an app launch, used later when app is activated.
    var launchedShortcutItem: UIApplicationShortcutItem?
    
    // MARK: - Application Life Cycle
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Override point for customization after application launch.
        
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
        
        var shouldPerformAdditionalDelegateHandling = true
        
        // If a shortcut was launched, display its information and take the appropriate action
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
            
            launchedShortcutItem = shortcutItem
            
            // This will block "performActionForShortcutItem:completionHandler" from being called.
            shouldPerformAdditionalDelegateHandling = false
        }
        
        // Install initial versions of our shortcuts.
        if let shortcutItems = application.shortcutItems where shortcutItems.isEmpty {
            let addShortcut = UIMutableApplicationShortcutItem(
                type: ShortcutIdentifier.Add.type,
                localizedTitle: NSLocalizedString("shortcut.addentry.title", comment: ""),
                localizedSubtitle: NSLocalizedString("shortcut.addentry.subtitle", comment: ""),
                icon: UIApplicationShortcutIcon(type: .Add),
                userInfo: [
                    AppDelegate.applicationShortcutUserInfoIconKey: UIApplicationShortcutIconType.Add.rawValue
                ])
            
            application.shortcutItems = [ addShortcut ]
        }
        
        setupAmplitudeSDK()
        
        return shouldPerformAdditionalDelegateHandling
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        CoreDataStack.shared.saveContext()
        WatchSessionManager.sharedManager.updateApplicationContext()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        showPasscodeIfNeeded()
        
        Amplitude.instance().logEvent("AppLaunch")
    }
    
    func applicationWillTerminate(application: UIApplication) {
        CoreDataStack.shared.saveContext()
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        guard let shortcutItem = launchedShortcutItem else {
            return
        }
        handleShortcutItem(shortcutItem)
        launchedShortcutItem = nil
    }
    
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        launchedShortcutItem = shortcutItem
        completionHandler(true)
    }
    
    // MARK: - Handle shortcut items
    
    private func handleShortcutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard ShortcutIdentifier(fullType: shortcutItem.type) != nil else {
            return false
        }
        
        guard let shortcutType = shortcutItem.type as String? else {
            return false
        }
        
        var handled = false
        
        let context = window!.rootViewController!
        
        switch shortcutType {
        case ShortcutIdentifier.Add.type:
            DeeplinkManager.invokeAddEntry(inContext: context)
            handled = true
            break
        default:
            break
        }
        
        return handled
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
        
        let now = NSDate()
        if let lastShown = lastPasscodeShown where lastShown.timeIntervalSinceDate(now) < 15 * 60 {
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
    
    // MARK: - Setup Amplitude SDK
    
    private func setupAmplitudeSDK() {
        #if DEBUG
            Amplitude.instance().initializeApiKey("e0aaa26848db06fa3c1d0ccd7cf283db")
        #else
            Amplitude.instance().initializeApiKey("c86e96179f239e19d7fa8a2a7d1d067f")
        #endif
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let userId = defaults.objectForKey("userId") as? String {
            Amplitude.instance().setUserId(userId)
        } else {
            let userId = NSUUID().UUIDString
            defaults.setObject(userId, forKey: "userId")
            defaults.synchronize()
            Amplitude.instance().setUserId(userId)
        }
        
        Amplitude.instance().trackingSessionEvents = true
        
        Amplitude.instance().logEvent("AppLaunch")
    }
}

