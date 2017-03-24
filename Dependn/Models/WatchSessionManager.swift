//
//  WatchSessionManager.swift
//  Dependn
//
//  Created by David Miotti on 27/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchConnectivity
import SwiftyJSON
import SwiftHelpers

final class WatchSessionManager: NSObject, WCSessionDelegate {
    /** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
    public func sessionDidDeactivate(_ session: WCSession) {
        
    }

    /** Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed. */
    public func sessionDidBecomeInactive(_ session: WCSession) {
        
    }

    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    static let sharedManager = WatchSessionManager()
    fileprivate override init() {
        super.init()
    }
    
    fileprivate let session: WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    
    fileprivate let watchQueue = OperationQueue()
    
    fileprivate var validSession: WCSession? {
        
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        
        if let session = session, session.isPaired && session.isWatchAppInstalled {
            return session
        }
        return nil
    }
    
    func startSession() {
        session?.delegate = self
        session?.activate()
    }
    
    func updateApplicationContext() {
        getNewEntry { [weak self] entries in
            self?.getStats { [weak self] stats in
                var context = entries
                context += stats
                do {
                    try self?.session?.updateApplicationContext(context)
                } catch let err as NSError {
                    print("Error while updating application context \(context): \(err)")
                }
            }
        }
    }
    
    fileprivate func getNewEntry(_ completion: @escaping (WatchDictionary) -> Void) {
        let newEntryOp = WatchNewEntryInfoOperation()
        newEntryOp.completionBlock = {
            var entryDict = WatchDictionary()
            if let result = newEntryOp.watchInfo {
                let value = WatchNewEntryInfoOperation.formatNewEntryResultsForAppleWatch(result)
                entryDict["value"] = value as AnyObject?
            } else if let err = newEntryOp.error, let sugg = err.localizedRecoverySuggestion {
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
            globalDict["new_entry"] = entryDict as AnyObject?
            completion(globalDict)
        }
        watchQueue.addOperation(newEntryOp)
    }
    
    fileprivate func getStats(_ completion: @escaping (WatchDictionary) -> Void) {
        let statsOp = WatchStatsOperation()
        statsOp.completionBlock = {
            var stats = WatchDictionary()
            if let result = statsOp.result {
                let res = WatchStatsOperation.formatStatsResultsForAppleWatch(result)
                stats["value"] = res as AnyObject?
            } else if let err = statsOp.error, let sugg = err.localizedRecoverySuggestion {
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
            globalDict["stats"] = stats as AnyObject?
            completion(globalDict)
        }
        watchQueue.addOperation(statsOp)
    }
}

func +=<K, V> (left: inout [K : V], right: [K : V]) {
    for (k, v) in right {
        left[k] = v
    }
}

extension WatchSessionManager {
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let json = JSON(message)
        try? handle(json: json)
    }
    
    private func handle(json message: JSON) throws {
        guard let action = message["action"].string else {
            updateApplicationContext()
            return
        }
        
        switch action {
        case "add":
            let data = message["data"]
            try handleAddAction(data: data)
            
        default:
            updateApplicationContext()
        }
    }
    
    private func handleAddAction(data: JSON) throws {
        let ctx = CoreDataStack.shared.managedObjectContext
        guard
            let addictionName = data["addiction"].string,
            let placeName = data["place"].string,
            let intensity = data["intensity"].float,
            let addiction = try Addiction.findByName(addictionName, inContext: ctx),
            let place = try Place.findByName(placeName, inContext: ctx) else {
                return
        }
        
        let isCraving = data["craving"].string == "craving"
            
        _ = Record.insertNewRecord(
            addiction,
            intensity: intensity,
            feeling: nil,
            comment: nil,
            place: place,
            latitude: nil,
            longitude: nil, desire:
            isCraving,
            inContext: ctx)
        
        Analytics.instance.trackAddNewRecord(
            addiction.name,
            place: place.name,
            intensity: intensity,
            conso: !isCraving,
            fromAppleWatch: true)
        
        PushSchedulerOperation.schedule(updateApplicationContext)
    }
}
