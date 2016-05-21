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

final class Analytics: NSObject {
    
    static let instance = Analytics()
    
    private let context: NSManagedObjectContext
    
    private override init() {
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
        Amplitude.instance().enableLocationListening()
        
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
        
        super.init()
        
        updateTrackingEnabledFromDefaults()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Analytics.applicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func updateUserProperties() {
        var props = [String: AnyObject]()
        
        let addictions = try! Addiction.getAllAddictions(inContext: context)
        props["addictions"] = addictions.map({ $0.name }).joinWithSeparator(";")
        
        let records = Record.recordCount(inContext: context)
        props["records"] = records
        
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.activateSession()
            props["watch"] = session.paired
        }
        
        Amplitude.instance().setUserProperties(props)
    }
    
    func trackSelectAddictions(addictions: [Addiction]) {
        let props = [ "addictions": addictions.map({ $0.name }).joinWithSeparator(";") ]
        Amplitude.instance().logEvent("SelectAddictions", withEventProperties: props)
        Analytics.instance.trackUserAddictions()
    }
    
    func trackUserAddictions() {
        if let addictions = try? Addiction.getAllAddictions(inContext: context) {
            let props = [ "addictions": addictions.map({ $0.name }).joinWithSeparator(";") ]
            Amplitude.instance().setUserProperties(props)
        }
    }
    
    func trackAddAddiction(addiction: Addiction) {
        Amplitude.instance().logEvent("AddAddiction", withEventProperties: ["addiction": addiction.name])
        trackUserAddictions()
    }
    
    func trackAddNewRecord(addiction: String, place: String?, intensity: Float, conso: Bool, fromAppleWatch appleWatch: Bool) {
        var props: [String: NSObject] = [
            "addiction": addiction,
            "intensity": intensity,
            "type": conso ? "conso" : "craving",
            "source": appleWatch ? "watch" : "phone"
        ]
        if let place = place {
            props["place"] = place
        }
        Amplitude.instance().logEvent("AddRecord", withEventProperties: props)
    }
    
    func trackAddPlace(place: String) {
        Amplitude.instance().logEvent("AddPlace", withEventProperties: ["place": place])
    }
    
    func trackExport(succeed: Bool) {
        Amplitude.instance().logEvent("Export", withEventProperties: ["result": succeed])
    }
    
    func trackRevenue(productIdentifier: String, price: Double, receipt: NSData? = nil) {
        Amplitude.instance().logRevenue(productIdentifier, quantity: 1, price: price)
    }
    
    func shareApp(target: String) {
        Amplitude.instance().logEvent("Share", withEventProperties: [ "target": target ])
    }

    func applicationDidBecomeActive(notification: NSNotification) {
        updateTrackingEnabledFromDefaults()
        Amplitude.instance().updateLocation()
    }
    
    private func updateTrackingEnabledFromDefaults() {
        let defaults = NSUserDefaults.standardUserDefaults()
        Amplitude.instance().optOut = !defaults.boolForKey("trackingEnabled")
    }
}
