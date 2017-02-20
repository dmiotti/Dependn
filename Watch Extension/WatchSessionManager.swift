//
//  WatchSessionManager.swift
//  Dependn
//
//  Created by David Miotti on 27/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchConnectivity
import ClockKit

let kWatchExtensionContextUpdatedNotificationName = "kWatchExtensionContextUpdated"
let kWatchExtensionContextErrorNotificationName = "kWatchExtensionContextError"

typealias WatchDictionary = Dictionary<String, AnyObject>
typealias WatchStatsValueTime = (value: String, date: String)

struct WatchSimpleModel {
    var name: String
    var uri: String
    
    init?(dict: WatchDictionary) {
        if let name = dict["name"] as? String, let uri = dict["uri"] as? String {
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
    var sinceLast: Date!
    
    var formattedSinceLast: String {
        let interval = Date().timeIntervalSince(sinceLast)
        return String(format: NSLocalizedString("watch.sinceLast", comment: ""), stringFromTimeInterval(interval: interval))
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

typealias RequestContextBlock = (AppContext) -> Void

final class WatchSessionManager: NSObject, WCSessionDelegate {
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(watchOS 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }

    
    let context = AppContext()
    
    static let sharedManager = WatchSessionManager()
    private override init() {
        super.init()
    }
    
    private let session: WCSession = WCSession.default()
    
    let newRecordModel = NewRecordModel()
    
    func startSession() {
        session.delegate = self
        session.activate()
    }

    private var getContextCompletionQueue = [RequestContextBlock]()

    func requestContext(block: RequestContextBlock? = nil) {

        if let block = block {
            getContextCompletionQueue.append(block)
        } else {
            getContextCompletionQueue.append({ ctx in })
        }

        if getContextCompletionQueue.count > 1 {
            return
        }

        let message = ["action": "context"]
        session.sendMessage(message, replyHandler: { response in
            
            self.parseApplicationContext(appContext: response as [String : AnyObject])

            self.unqueueContextBlocks()
            
            }, errorHandler: { err in

                self.unqueueContextBlocks()
                
                NotificationCenter.default.postNotificationName(
                    kWatchExtensionContextErrorNotificationName,
                    object: nil, userInfo: [ "error": err ])
        })
    }

    private func unqueueContextBlocks() {
        for block in getContextCompletionQueue {
            block(context)
        }
        getContextCompletionQueue.removeAll()
    }
    
    func sendAdd() {
        let record = WatchSessionManager.sharedManager.newRecordModel
        if let
            addiction = record.addiction?.name,
            let place = record.place?.name {
            
            let message: [String: AnyObject] = [
                "action": "add" as AnyObject,
                "data": [
                    "type": record.type == .Conso ? "conso" : "craving",
                    "addiction": addiction,
                    "place": place,
                    "intensity": "\(record.intensity)"
                ]
            ]
            
            session.sendMessage(message, replyHandler: { response in
                
                self.parseApplicationContext(appContext: response)
                
                }, errorHandler: { err in
                    
                    NotificationCenter.default.postNotificationName(
                        kWatchExtensionContextErrorNotificationName,
                        object: nil, userInfo: [ "error": err ])
            })
        }
    }
    
    fileprivate func parseApplicationContext(appContext: [String: AnyObject]) {
        
        /// Parse stats context
        let statsContext = appContext["stats"] as? WatchDictionary
        let statsContextValue = statsContext?["value"] as? WatchDictionary
        
        if let name = statsContextValue?["name"] as? String {
            let stats = WatchStatsAddiction()
            stats.addiction = name
            
            if let sinceLast = statsContextValue?["sinceLast"] as? Date {
                stats.sinceLast = sinceLast
            }
            
            if let rawValues = statsContextValue?["value"] as? [Array<AnyObject>] {
                for raw in rawValues {
                    if let date = raw.last as? String, let count = raw.first as? String {
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
            let model = WatchSimpleModel(dict: mostUsedAddiction) {
            context.mostUsedAddiction = model
        }
        
        /// Parse most used place
        if let
            mostUsedPlace = addContextValue?["most_used_place"] as? WatchDictionary,
            let model = WatchSimpleModel(dict: mostUsedPlace) {
            context.mostUsedPlace = model
        }
        
        if let statsError = statsContext?["error"] as? WatchDictionary, let err = parseError(dict: statsError) {
            NotificationCenter.default.postNotificationName(
                kWatchExtensionContextErrorNotificationName,
                object: nil, userInfo: [ "error": err ])
        } else if let addError = addContext?["error"] as? WatchDictionary, let err = parseError(dict: addError) {
            NotificationCenter.default.postNotificationName(
                kWatchExtensionContextErrorNotificationName,
                object: nil, userInfo: [ "error": err ])
        }
        
        NotificationCenter.default.postNotificationName(
            kWatchExtensionContextUpdatedNotificationName,
            object: nil, userInfo: ["context": context])
    }
    
    private func parseError(dict: WatchDictionary) -> NSError? {
        if let desc = dict["description"] as? String, let sugg = dict["suggestion"] as? String {
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
        parseApplicationContext(appContext: applicationContext)
    }
}
