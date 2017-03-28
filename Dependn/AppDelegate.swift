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
import CoreData

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: Types
    
    enum ShortcutIdentifier: String {
        case Add
        
        // MARK: Initializers
        
        init?(fullType: String) {
            guard let last = fullType.components(separatedBy: ".").last else {
                return nil
            }
            
            self.init(rawValue: last)
        }
        
        // MARK: Properties
        
        var type: String {
            return Bundle.main.bundleIdentifier! + ".\(self.rawValue)"
        }
    }
    
    // MARK: Static properties
    
    static let applicationShortcutUserInfoIconKey = "applicationShortcutUserInfoIconKey"
    
    // MARK: Properties

    fileprivate(set) var checkForPasscode: Bool = true
    
    var window: UIWindow?
    
    /// Saved shortcut item used as a result of an app launch, used later when app is activated.
    var launchedShortcutItem: UIApplicationShortcutItem?
    
    // MARK: - Application Life Cycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        initializeCoreDataStack()
        
        // Register defaults properties in Settings app
        let defaults = UserDefaults.standard
        let appDefaults = [ "trackingEnabled": true ]
        defaults.register(defaults: appDefaults)
        defaults.synchronize()
        
        // Setup Fabric
        Fabric.with([Crashlytics.self])
        
        StyleSheet.customizeAppearance(window)
        
        WatchSessionManager.sharedManager.startSession()
        WatchSessionManager.sharedManager.updateApplicationContext()
        
        var shouldPerformAdditionalDelegateHandling = true
        
        // If a shortcut was launched, display its information and take the appropriate action
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            
            launchedShortcutItem = shortcutItem
            
            // This will block "performActionForShortcutItem:completionHandler" from being called.
            shouldPerformAdditionalDelegateHandling = false
        }
        
        // Install initial versions of our shortcuts.
        if let shortcutItems = application.shortcutItems, shortcutItems.isEmpty {
            let addShortcut = UIMutableApplicationShortcutItem(
                type: ShortcutIdentifier.Add.type,
                localizedTitle: NSLocalizedString("shortcut.addentry.title", comment: ""),
                localizedSubtitle: NSLocalizedString("shortcut.addentry.subtitle", comment: ""),
                icon: UIApplicationShortcutIcon(type: .add),
                userInfo: [
                    AppDelegate.applicationShortcutUserInfoIconKey: UIApplicationShortcutIconType.add.rawValue
                ])
            
            application.shortcutItems = [ addShortcut ]
        }
        
        saveCurrentAppVersion()

        return shouldPerformAdditionalDelegateHandling
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {

        var bgTask: UIBackgroundTaskIdentifier!

        bgTask = application.beginBackgroundTask (expirationHandler: {
            application.endBackgroundTask(bgTask)
            bgTask = UIBackgroundTaskInvalid
        })

        CoreDataStack.shared.saveContext()
        WatchSessionManager.sharedManager.updateApplicationContext()
        Analytics.instance.updateUserProperties()

        let schedulePush = PushSchedulerOperation(context: CoreDataStack.shared.managedObjectContext)
        schedulePush.completionBlock = {
            application.endBackgroundTask(bgTask)
            bgTask = UIBackgroundTaskInvalid
        }

        OperationQueue().addOperation(schedulePush)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        checkForPasscode = true
        showPasscodeIfNeeded()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        CoreDataStack.shared.saveContext()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        showPasscodeIfNeeded()

        guard let shortcutItem = launchedShortcutItem else {
            return
        }

        _ = handleShortcutItem(shortcutItem)
        launchedShortcutItem = nil
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        launchedShortcutItem = shortcutItem
        completionHandler(true)
    }

    // MARK: - Pushes

    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types.contains(.alert) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: kUserAcceptPushPermissions), object: nil, userInfo: nil)

            PushSchedulerOperation.schedule()
            application.registerForRemoteNotifications()
        } else {
            NotificationCenter.default.post(name: Notification.Name(rawValue: kUserRejectPushPermissions), object: nil, userInfo: nil)
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Analytics.instance.trackDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {

    }
    
    // MARK: - Initialize CoreDataStack
    
    private func initializeCoreDataStack() {
        let needMigration = Defaults[.alreadyLaunched] && !Defaults[.didiCloudCheck]
        Defaults[.didiCloudCheck] = true
        if needMigration {
            var opts: [AnyHashable: Any] = [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true,
                NSPersistentStoreFileProtectionKey: FileProtectionType.completeUntilFirstUserAuthentication,
                NSPersistentStoreRemoveUbiquitousMetadataOption: true
            ]
            if !DeviceType.isSimulator {
                opts[NSPersistentStoreUbiquitousContentNameKey] = "Dependn"
            }
            CoreDataStack.initializeWithMomd("Dependn", sql: "Dependn.sqlite", persistantStoreOptions: opts)
        } else {
            CoreDataStack.initializeWithMomd("Dependn", sql: "Dependn.sqlite")
        }
    }
    
    // MARK: - Saves the current app version
    
    private func saveCurrentAppVersion() {
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return
        }
        Defaults[.appVersion] = currentVersion
        Defaults.synchronize()
    }
    
    // MARK: - Handle shortcut items
    
    fileprivate func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
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
    
    fileprivate var hidingNav: SHStatusBarNavigationController?
    fileprivate var lastPasscodeShown: Date?
    
    fileprivate func showPasscodeIfNeeded() {
        guard
            checkForPasscode &&
            hidingNav == nil &&
                PasscodeViewController.supportedOwnerAuthentications().count > 0 &&
                Defaults[.usePasscode] == true else {
                    DDLogInfo("Passcode is already shown or is unsupported")
                    return
        }

        checkForPasscode = false
        
        let now = Date()
        if let lastShown = lastPasscodeShown, lastShown.timeIntervalSince(now) < 15 * 60 {
            return
        }
        
        presentPasscode()
    }
    
    fileprivate func presentPasscode() {
        if let rootViewController = window?.rootViewController, rootViewController.isViewLoaded {
            var topController = rootViewController
            while let top = topController.presentedViewController {
                topController = top
            }
            
            lastPasscodeShown = Date()
            
            let passcodeViewController = PasscodeViewController()
            hidingNav = SHStatusBarNavigationController(rootViewController: passcodeViewController)
            hidingNav!.statusBarStyle = .lightContent
            hidingNav!.modalTransitionStyle = .crossDissolve
            topController.present(hidingNav!, animated: false, completion: nil)
        }
    }
}

