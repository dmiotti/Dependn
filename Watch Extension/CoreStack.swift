//
//  CoreStack.swift
//  Dependn
//
//  Created by David Miotti on 25/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import WatchConnectivity

typealias WatchDictionary = Dictionary<String, AnyObject>
typealias WatchStatsValueTime = (value: String, date: NSDate)

final class WatchStatsAddiction {
    var addiction = ""
    var values = [WatchStatsValueTime]()
}

private let kCoreStackErrorDomain = "CoreStack"

final class CoreStack: NSObject {
    
    static let shared = CoreStack()
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
            }
        }
    }
    
    var cachedStats: WatchStatsAddiction?
    
    func getStats(block: (WatchStatsAddiction?, NSError?) -> Void) {
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
            session?.sendMessage(["action": "stats"], replyHandler: { (response) in
                
                if let
                    error = response["error"] as? WatchDictionary,
                    desc = error["description"] as? String,
                    suggestion = error["suggestion"] {
                    
                    let err = NSError(domain: kCoreStackErrorDomain, code: 0, userInfo: [
                        NSLocalizedDescriptionKey: desc,
                        NSLocalizedRecoverySuggestionErrorKey: suggestion
                    ])
                    
                    block(nil, err)
                    
                } else if let rawAddiction = response["stats"] as? WatchDictionary, name = rawAddiction["name"] as? String {
                    let addictions = WatchStatsAddiction()
                    addictions.addiction = name
                    if let rawValues = rawAddiction["value"] as? [Array<AnyObject>] {
                        for rawValue in rawValues {
                            if let date = rawValue.last as? NSDate, count = rawValue.first as? String {
                                addictions.values.append((count, date))
                            }
                        }
                    }
                    self.cachedStats = addictions
                    block(addictions, nil)
                } else {
                    let err = NSError(domain: kCoreStackErrorDomain, code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "An unknown error has occur",
                        NSLocalizedRecoverySuggestionErrorKey: "Please try again later"
                    ])
                    
                    block(nil, err)
                }
                
                }, errorHandler: { (err) in
                    
                    block(nil, err)
            })
        }
    }
    
}

extension CoreStack: WCSessionDelegate {
    
}
