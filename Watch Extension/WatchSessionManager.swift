//
//  WatchSessionManager.swift
//  Dependn
//
//  Created by David Miotti on 27/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchConnectivity

let kWatchExtensionContextUpdatedNotificationName = "kWatchExtensionContextUpdated"
let kWatchExtensionContextErrorNotificationName = "kWatchExtensionContextError"

typealias WatchDictionary = Dictionary<String, AnyObject>
typealias WatchStatsValueTime = (value: String, date: NSDate)

struct WatchSimpleModel {
    var name: String
    var uri: String
}

final class WatchStatsAddiction {
    var addiction = ""
    var values = [WatchStatsValueTime]()
    var sinceLast: String?
}

final class AppContext {
    var stats: WatchStatsAddiction?
    var addictions = [WatchSimpleModel]()
    var places = [WatchSimpleModel]()
}

final class WatchSessionManager: NSObject, WCSessionDelegate {
    
    let context = AppContext()
    
    static let sharedManager = WatchSessionManager()
    private override init() {
        super.init()
    }
    
    private let session: WCSession = WCSession.defaultSession()
    
    var newEntryData = [String: AnyObject]()
    
    func startSession() {
        session.delegate = self
        session.activateSession()
    }
    
    func requestContext() {
        session.sendMessage(["action": "get_context"], replyHandler: { res in
            self.parseApplicationContext(res)
            }, errorHandler: { err in
                NSNotificationCenter.defaultCenter().postNotificationName(
                    kWatchExtensionContextErrorNotificationName,
                    object: nil, userInfo: [ "error": err ])
        })
    }
    
    private func parseApplicationContext(appContext: [String: AnyObject]) {
        if let
            rawAddiction = appContext["stats"] as? WatchDictionary,
            name = rawAddiction["name"] as? String {
            
            let addiction = WatchStatsAddiction()
            addiction.addiction = name
            
            if let sinceLast = rawAddiction["sinceLast"] as? String {
                addiction.sinceLast = sinceLast
            }
            
            if let rawValues = rawAddiction["value"] as? [Array<AnyObject>] {
                for rawValue in rawValues {
                    if let date = rawValue.last as? NSDate, count = rawValue.first as? String {
                        addiction.values.append((count, date))
                    }
                }
            }
            
            context.stats = addiction
        }
        
        let newEntry = appContext["new_entry"] as? WatchDictionary
        if let newEntry = newEntry {
            if let addictions = newEntry["addictions"] as? [WatchDictionary] {
                for add in addictions {
                    if let name = add["name"] as? String, uri = add["uri"] as? String {
                        let model = WatchSimpleModel(name: name, uri: uri)
                        context.addictions.append(model)
                    }
                }
            }
            if let places = newEntry["places"] as? [WatchDictionary] {
                for place in places {
                    if let name = place["name"] as? String, uri = place["uri"] as? String {
                        let model = WatchSimpleModel(name: name, uri: uri)
                        context.places.append(model)
                    }
                }
            }
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            kWatchExtensionContextUpdatedNotificationName,
            object: nil, userInfo: ["context": context])
        
        if let
            error = appContext["error"] as? WatchDictionary,
            desc = error["description"] as? String,
            suggestion = error["suggestion"] as? String {
            
            let err = NSError(domain: "WatchSessionManager", code: 0, userInfo: [
                NSLocalizedDescriptionKey: desc,
                NSLocalizedRecoverySuggestionErrorKey: suggestion
                ])
            
            NSNotificationCenter.defaultCenter().postNotificationName(
                kWatchExtensionContextErrorNotificationName,
                object: nil, userInfo: [ "error": err ])
        }
    }
}

extension WatchSessionManager {
    
    // Receiving data
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        
        parseApplicationContext(applicationContext)
    }
}