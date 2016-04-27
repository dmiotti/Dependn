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
    
    private func buildApplicationContext(completion: [String: AnyObject] -> Void) {
        let watchQueue = NSOperationQueue()
        watchQueue.maxConcurrentOperationCount = 1
        
        var context = WatchDictionary()
        
        watchQueue.suspended = true
        
        let newEntryOp = WatchNewEntryInfoOperation()
        newEntryOp.completionBlock = {
            if let result = newEntryOp.watchInfo {
                let res = WatchNewEntryInfoOperation.formatNewEntryResultsForAppleWatch(result)
                context["new_entry"] = res
            } else if let err = newEntryOp.error, sugg = err.localizedRecoverySuggestion {
                context["error"] = [
                    "description": err.localizedDescription,
                    "suggestion": sugg
                ]
            } else {
                context["error"] = [
                    "description": L("error.unknown"),
                    "suggestion": L("error.unknown.suggestion")
                ]
            }
            
            let finalBlock = NSBlockOperation {
                completion(context)
            }
            watchQueue.addOperation(finalBlock)
        }
        
        let statsOp = WatchStatsOperation()
        statsOp.completionBlock = {
            if let result = statsOp.result {
                let res = WatchStatsOperation.formatStatsResultsForAppleWatch(result)
                context["stats"] = res
            } else if let err = statsOp.error, sugg = err.localizedRecoverySuggestion {
                context["error"] = [
                    "description": err.localizedDescription,
                    "suggestion": sugg
                ]
            } else {
                context["error"] = [
                    "description": L("error.unknown"),
                    "suggestion": L("error.unknown.suggestion")
                ]
            }
            
            watchQueue.addOperation(newEntryOp)
        }
        
        watchQueue.addOperation(statsOp)
        
        watchQueue.suspended = false
    }
}


extension WatchSessionManager {
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        
        if let action = message["action"] as? String {
            
            switch action {
            case "get_context":
                buildApplicationContext { context in
                    replyHandler(context)
                }
            default:
                break
            }
            
        }
        
    }
}
