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
        let message = ["action": "context"]
        session.sendMessage(message, replyHandler: { response in
            
            self.parseApplicationContext(response)
            
            }, errorHandler: { err in
                
                NSNotificationCenter.defaultCenter().postNotificationName(
                    kWatchExtensionContextErrorNotificationName,
                    object: nil, userInfo: [ "error": err ])
        })
    }
    
    func sendAdd() {
        let entry = WatchSessionManager.sharedManager.newEntryData
        let message: [String: AnyObject] = [ "action": "add", "data": entry ]
        session.sendMessage(message, replyHandler: { response in
            
            self.parseApplicationContext(response)
            
            }, errorHandler: { err in
                
                NSNotificationCenter.defaultCenter().postNotificationName(
                    kWatchExtensionContextErrorNotificationName,
                    object: nil, userInfo: [ "error": err ])
        })
    }
    
    private func parseApplicationContext(appContext: [String: AnyObject]) {
        
//        print("appContext: \(appContext)")
        
        /// Parse stats context
        let statsContext = appContext["stats"] as? WatchDictionary
        let statsContextValue = statsContext?["value"] as? WatchDictionary
        
        if let name = statsContextValue?["name"] as? String {
            let stats = WatchStatsAddiction()
            stats.addiction = name
            
            if let sinceLast = statsContextValue?["sinceLast"] as? String {
                stats.sinceLast = sinceLast
            }
            
            if let rawValues = statsContextValue?["value"] as? [Array<AnyObject>] {
                for raw in rawValues {
                    if let date = raw.last as? NSDate, count = raw.first as? String {
                        stats.values.append((count, date))
                    }
                }
            }
            
            context.stats = stats
        }
        
        
        /// Parse new entry context
        let addContext = appContext["new_entry"] as? WatchDictionary
        let addContextValue = addContext?["value"] as? WatchDictionary
        
        /// Starts with addictions
        if let addictions = addContextValue?["addictions"] as? [WatchDictionary] {
            var adds = [WatchSimpleModel]()
            for add in addictions {
                if let name = add["name"] as? String, uri = add["uri"] as? String {
                    let model = WatchSimpleModel(name: name, uri: uri)
                    adds.append(model)
                }
            }
            context.addictions = adds
        }
        
        /// Parse places
        if let places = addContextValue?["places"] as? [WatchDictionary] {
            var all = [WatchSimpleModel]()
            for place in places {
                if let name = place["name"] as? String, uri = place["uri"] as? String {
                    let model = WatchSimpleModel(name: name, uri: uri)
                    all.append(model)
                }
            }
            context.places = all
        }
        
        if let statsError = statsContext?["error"] as? WatchDictionary, err = parseError(statsError) {
            NSNotificationCenter.defaultCenter().postNotificationName(
                kWatchExtensionContextErrorNotificationName,
                object: nil, userInfo: [ "error": err ])
        } else if let addError = addContext?["error"] as? WatchDictionary, err = parseError(addError) {
            NSNotificationCenter.defaultCenter().postNotificationName(
                kWatchExtensionContextErrorNotificationName,
                object: nil, userInfo: [ "error": err ])
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            kWatchExtensionContextUpdatedNotificationName,
            object: nil, userInfo: ["context": context])
    }
    
    private func parseError(dict: WatchDictionary) -> NSError? {
        if let desc = dict["description"] as? String, sugg = dict["suggestion"] as? String {
            return NSError(domain: "WatchSessionManager", code: 0, userInfo: [
                NSLocalizedDescriptionKey: desc,
                NSLocalizedRecoverySuggestionErrorKey: sugg
            ])
        }
        return nil
    }
}

extension WatchSessionManager {
    
    // Receiving data
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        
        parseApplicationContext(applicationContext)
    }
}