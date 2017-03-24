//
//  Analytics.swift
//  Dependn
//
//  Created by David Miotti on 08/05/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import Amplitude_iOS
import CoreData
import WatchConnectivity
import SwiftyUserDefaults

final class Analytics: NSObject {
    
    static let instance = Analytics()
    
    fileprivate let context: NSManagedObjectContext
    
    fileprivate override init() {
        #if DEBUG
            Amplitude.instance().initializeApiKey("e0aaa26848db06fa3c1d0ccd7cf283db")
        #else
            Amplitude.instance().initializeApiKey("c86e96179f239e19d7fa8a2a7d1d067f")
        #endif
        
        let defaults = UserDefaults.standard
        if let userId = defaults.object(forKey: "userId") as? String {
            Amplitude.instance().setUserId(userId)
        } else {
            let userId = UUID().uuidString
            defaults.set(userId, forKey: "userId")
            defaults.synchronize()
            Amplitude.instance().setUserId(userId)
        }
        
        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().enableLocationListening()
        
        context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = CoreDataStack.shared.managedObjectContext
        
        super.init()
        
        updateTrackingEnabledFromDefaults()
        
        NotificationCenter.default.addObserver(self, selector: #selector(Analytics.applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateUserProperties() {
        var props = [String: Any]()
        
        let addictions = try! Addiction.getAllAddictions(inContext: context)
        props["addictions"] = addictions.map({ $0.name }).joined(separator: ";")
        
        let records = try! Record.recordCount(inContext: context)
        props["records"] = records
        
        if WCSession.isSupported() {
            let session = WCSession.default()
            session.activate()
            props["watch"] = session.isPaired as AnyObject?
        }

        props["usePasscode"] = Defaults[.usePasscode]
        
        props["useLocation"] = Defaults[.useLocation]

        props["push"] = UIApplication.shared.isRegisteredForRemoteNotifications as AnyObject?

        if let settings = UIApplication.shared.currentUserNotificationSettings {
            props["localpush"] = settings.types.contains(.alert) as AnyObject?
        }

        Amplitude.instance().setUserProperties(props)
    }
    
    func trackSelectAddictions(_ addictions: [Addiction]) {
        let props = [ "addictions": addictions.map({ $0.name }).joined(separator: ";") ]
        Amplitude.instance().logEvent("SelectAddictions", withEventProperties: props)
        Analytics.instance.trackUserAddictions()
    }
    
    func trackUserAddictions() {
        if let addictions = try? Addiction.getAllAddictions(inContext: context) {
            let props = [ "addictions": addictions.map({ $0.name }).joined(separator: ";") ]
            Amplitude.instance().setUserProperties(props)
        }
    }
    
    func trackAddAddiction(_ addiction: Addiction) {
        Amplitude.instance().logEvent("AddAddiction", withEventProperties: ["addiction": addiction.name])
        trackUserAddictions()
    }
    
    func trackAddNewRecord(_ addiction: String, place: String?, intensity: Float, conso: Bool, fromAppleWatch appleWatch: Bool) {
        var props: [String: Any] = [
            "addiction": addiction as NSObject,
            "intensity": intensity as NSObject,
            "type": conso ? "conso" : "craving",
            "source": appleWatch ? "watch" : "phone"
        ]
        if let place = place {
            props["place"] = place
        }
        Amplitude.instance().logEvent("AddRecord", withEventProperties: props)
    }
    
    func trackAddPlace(_ place: String) {
        Amplitude.instance().logEvent("AddPlace", withEventProperties: ["place": place])
    }
    
    func trackExport(_ succeed: Bool) {
        Amplitude.instance().logEvent("Export", withEventProperties: ["result": succeed])
    }
    
    func trackRevenue(_ productIdentifier: String, price: Double, receipt: Data? = nil) {
        Amplitude.instance().logRevenue(productIdentifier, quantity: 1, price: price as NSNumber!)
    }

    func trackDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.parseDeviceToken()
        Amplitude.instance().setUserProperties([ "deviceToken": tokenString ])
    }
    
    func shareApp(_ target: String) {
        Amplitude.instance().logEvent("Share", withEventProperties: [ "target": target ])
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        updateTrackingEnabledFromDefaults()
        Amplitude.instance().updateLocation()
    }
    
    fileprivate func updateTrackingEnabledFromDefaults() {
        let defaults = UserDefaults.standard
        Amplitude.instance().optOut = !defaults.bool(forKey: "trackingEnabled")
    }
}
