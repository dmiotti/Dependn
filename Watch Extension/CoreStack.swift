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

final class CoreStackContext {
    var stats: WatchStatsAddiction?
    var newEntry: WatchDictionary?
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
    
    let context = CoreStackContext()
    
    func getContext(block: (CoreStackContext?, NSError?) -> Void) {
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
            session?.sendMessage(["action": "get_context"], replyHandler: { (response) in
                
                if let
                    error = response["error"] as? WatchDictionary,
                    desc = error["description"] as? String,
                    suggestion = error["suggestion"] {
                    
                    let err = NSError(domain: kCoreStackErrorDomain, code: 0, userInfo: [
                        NSLocalizedDescriptionKey: desc,
                        NSLocalizedRecoverySuggestionErrorKey: suggestion
                    ])
                    
                    block(nil, err)
                    return
                }
                
                if let rawAddiction = response["stats"] as? WatchDictionary, name = rawAddiction["name"] as? String {
                    let addictions = WatchStatsAddiction()
                    addictions.addiction = name
                    if let rawValues = rawAddiction["value"] as? [Array<AnyObject>] {
                        for rawValue in rawValues {
                            if let date = rawValue.last as? NSDate, count = rawValue.first as? String {
                                addictions.values.append((count, date))
                            }
                        }
                    }
                    
                    self.context.stats = addictions
                }
                
                if let newEntry = response["new_entry"] as? WatchDictionary {
                    print("newEntry: \(newEntry)")
                    self.context.newEntry = newEntry
                }
                
                block(self.context, nil)
                
                }, errorHandler: { (err) in
                    
                    block(nil, err)
            })
        } else {
            block(nil, nil)
        }
    }
    
}

extension CoreStack: WCSessionDelegate {
    
}
