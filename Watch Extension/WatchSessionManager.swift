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
typealias WatchStatsValueTime = (value: String, date: String)

struct WatchSimpleModel {
    var name: String
    var uri: String
    
    init?(dict: WatchDictionary) {
        if let name = dict["name"] as? String, uri = dict["uri"] as? String {
            self.name = name
            self.uri = uri
        } else {
            return nil
        }
    }
}

final class WatchStatsAddiction {
    var addiction = ""
    var values = [WatchStatsValueTime]()
    var sinceLast: NSTimeInterval = 0
    
    var formattedSinceLast: String {
        return String(format: NSLocalizedString("watch.sinceLast", comment: ""), stringFromTimeInterval(sinceLast))
    }
}

final class AppContext {
    var stats: WatchStatsAddiction?
    var addictions = [WatchSimpleModel]()
    var places = [WatchSimpleModel]()
    var mostUsedAddiction: WatchSimpleModel?
    var mostUsedPlace: WatchSimpleModel?
}

enum NewRecordType {
    case Conso, Craving
}

final class NewRecordModel {
    var type: NewRecordType = .Conso
    var place: WatchSimpleModel?
    var addiction: WatchSimpleModel?
    var intensity: Float = 7
}

final class WatchSessionManager: NSObject, WCSessionDelegate {
    
    let context = AppContext()
    
    static let sharedManager = WatchSessionManager()
    private override init() {
        super.init()
    }
    
    private let session: WCSession = WCSession.defaultSession()
    
    let newRecordModel = NewRecordModel()
    
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
        let record = WatchSessionManager.sharedManager.newRecordModel
        if let
            addiction = record.addiction?.name,
            place = record.place?.name {
            
            let message: [String: AnyObject] = [
                "action": "add",
                "data": [
                    "type": record.type == .Conso ? "conso" : "craving",
                    "addiction": addiction,
                    "place": place,
                    "intensity": "\(record.intensity)"
                ]
            ]
            
            session.sendMessage(message, replyHandler: { response in
                
                self.parseApplicationContext(response)
                
                }, errorHandler: { err in
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        kWatchExtensionContextErrorNotificationName,
                        object: nil, userInfo: [ "error": err ])
            })
        }
    }
    
    private func parseApplicationContext(appContext: [String: AnyObject]) {
        
        print("appContext: \(appContext)")
        
        /// Parse stats context
        let statsContext = appContext["stats"] as? WatchDictionary
        let statsContextValue = statsContext?["value"] as? WatchDictionary
        
        if let name = statsContextValue?["name"] as? String {
            let stats = WatchStatsAddiction()
            stats.addiction = name
            
            if let sinceLast = statsContextValue?["sinceLast"] as? NSTimeInterval {
                stats.sinceLast = sinceLast
            }
            
            if let rawValues = statsContextValue?["value"] as? [Array<AnyObject>] {
                for raw in rawValues {
                    if let date = raw.last as? String, count = raw.first as? String {
                        stats.values.append((count, date))
                    }
                }
            }
            
            context.stats = stats
        }
        
        /// Parse new entry context
        let addContext = appContext["new_entry"] as? WatchDictionary
        let addContextValue = addContext?["value"] as? WatchDictionary
        
        /// Parse addictions
        if let addictions = addContextValue?["addictions"] as? [WatchDictionary] {
            context.addictions = addictions.flatMap {
                WatchSimpleModel(dict: $0)
            }
        }
        
        /// Parse places
        if let places = addContextValue?["places"] as? [WatchDictionary] {
            context.places = places.flatMap {
                WatchSimpleModel(dict: $0)
            }
        }
        
        /// Parse most used addiction
        if let
            mostUsedAddiction = addContextValue?["most_used_addiction"] as? WatchDictionary,
            model = WatchSimpleModel(dict: mostUsedAddiction) {
            context.mostUsedAddiction = model
        }
        
        /// Parse most used place
        if let
            mostUsedPlace = addContextValue?["most_used_place"] as? WatchDictionary,
            model = WatchSimpleModel(dict: mostUsedPlace) {
            context.mostUsedPlace = model
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