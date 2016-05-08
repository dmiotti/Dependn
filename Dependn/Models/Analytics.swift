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

final class Analytics {
    
    static let instance = Analytics()
    
    private let context: NSManagedObjectContext
    
    private init() {
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
        
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
    }
    
    func appLaunch() {
        Amplitude.instance().logEvent("AppLaunch")
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

}
