//
//  WatchSessionManager.swift
//  Dependn
//
//  Created by David Miotti on 27/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchConnectivity
import SwiftHelpers

final class WatchSessionManager: NSObject, WCSessionDelegate {
    
    static let sharedManager = WatchSessionManager()
    private override init() {
        super.init()
    }
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil
    
    private let watchQueue = NSOperationQueue()
    
    private var validSession: WCSession? {
        
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        
        if let session = session where session.paired && session.watchAppInstalled {
            return session
        }
        return nil
    }
    
    func startSession() {
        session?.delegate = self
        session?.activateSession()
    }
    
    func updateApplicationContext() {
        if let session = validSession {
            buildApplicationContext { context in
                do {
                    try session.updateApplicationContext(context)
                } catch let err as NSError {
                    print("Error while updating application context \(context): \(err)")
                }
            }
        }
    }
    
    private func buildApplicationContext(completion: WatchDictionary -> Void) {
        getNewEntry { entries in
            self.getStats { stats in
                var context = entries
                context += stats
                completion(context)
            }
        }
    }
    
    private func getNewEntry(completion: WatchDictionary -> Void) {
        let newEntryOp = WatchNewEntryInfoOperation()
        newEntryOp.completionBlock = {
            
            var entryDict = WatchDictionary()
            if let result = newEntryOp.watchInfo {
                let value = WatchNewEntryInfoOperation.formatNewEntryResultsForAppleWatch(result)
                entryDict["value"] = value
            } else if let err = newEntryOp.error, sugg = err.localizedRecoverySuggestion {
                entryDict["error"] = [
                    "description": err.localizedDescription,
                    "suggestion": sugg
                ]
            } else {
                entryDict["error"] = [
                    "description": L("error.unknown"),
                    "suggestion": L("error.unknown.suggestion")
                ]
            }
            
            var globalDict = WatchDictionary()
            globalDict["new_entry"] = entryDict
            completion(globalDict)
        }
        watchQueue.addOperation(newEntryOp)
    }
    
    private func getStats(completion: WatchDictionary -> Void) {
        let statsOp = WatchStatsOperation()
        statsOp.completionBlock = {
            
            var stats = WatchDictionary()
            if let result = statsOp.result {
                let res = WatchStatsOperation.formatStatsResultsForAppleWatch(result)
                stats["value"] = res
            } else if let err = statsOp.error, sugg = err.localizedRecoverySuggestion {
                stats["error"] = [
                    "description": err.localizedDescription,
                    "suggestion": sugg
                ]
            } else {
                stats["error"] = [
                    "description": L("error.unknown"),
                    "suggestion": L("error.unknown.suggestion")
                ]
            }
            
            var globalDict = WatchDictionary()
            globalDict["stats"] = stats
            completion(globalDict)
        }
        watchQueue.addOperation(statsOp)
    }
}

func +=<K, V> (inout left: [K : V], right: [K : V]) {
    for (k, v) in right {
        left[k] = v
    }
}

extension WatchSessionManager {
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        guard let action = message["action"] as? String else {
            buildApplicationContext { replyHandler($0) }
            return
        }

        switch action {
        case "add":
            let data = message["data"] as? WatchDictionary
            let rawAddiction = data?["addiction"] as? String
            let rawPlace = data?["place"] as? String
            let rawIntensity = data?["intensity"] as? String
            let isCraving = data?["type"] as? String == "craving"
            
            if let
                rawAddiction = rawAddiction,
                rawPlace = rawPlace,
                rawIntensity = rawIntensity,
                intensity = Float(rawIntensity) {
                
                let ctx = CoreDataStack.shared.managedObjectContext
                do {
                    
                    let addiction = try Addiction.findByName(rawAddiction, inContext: ctx)
                    let place = try Place.findByName(rawPlace, inContext: ctx)
                    
                    if let add = addiction, place = place {
                        Record.insertNewRecord(
                            add,
                            intensity: intensity,
                            feeling: nil,
                            comment: nil,
                            place: place,
                            latitude: nil,
                            longitude: nil, desire:
                            isCraving,
                            inContext: ctx)
                        
                        Analytics.instance.trackAddNewRecord(
                            add.name,
                            place: place.name,
                            intensity: intensity,
                            conso: !isCraving,
                            fromAppleWatch: true)

                        PushSchedulerOperation.schedule {
                            self.buildApplicationContext {
                                replyHandler($0)
                            }
                        }
                    }
                    
                    
                } catch let err as NSError {
                    print("Error while replying to Apple Watch: \(err)")
                }
            }

        default:
            buildApplicationContext { replyHandler($0) }
        }
    }
}
