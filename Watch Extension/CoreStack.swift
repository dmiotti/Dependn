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

class WatchStatsAddiction {
    var addiction = ""
    var values = [WatchStatsValueTime]()
}

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
    
    var cachedStats: [WatchStatsAddiction]?
    
    func getStats(block: [WatchStatsAddiction] -> Void) {
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
            session?.sendMessage(["action": "stats"], replyHandler: { (response) in
                
                var addictions = [WatchStatsAddiction]()
                if let values = response["stats"] as? [WatchDictionary] {
                    
                    for rawAddiction in values {
                        if let name = rawAddiction["name"] as? String {
                            let statsAddiction = WatchStatsAddiction()
                            statsAddiction.addiction = name
                            if let rawValues = rawAddiction["value"] as? [Array<AnyObject>] {
                                for rawValue in rawValues {
                                    if let date = rawValue.last as? NSDate, count = rawValue.first as? String {
                                        statsAddiction.values.append((count, date))
                                    }
                                }
                            }
                            addictions.append(statsAddiction)
                        }
                    }
                }
                
                self.cachedStats = addictions
                
                dispatch_async(dispatch_get_main_queue()) {
                    block(addictions)
                }
                
                }, errorHandler: { (err) in
                    print(err)
                    block([])
            })
        }
    }
    
}

extension CoreStack: WCSessionDelegate {
    
}
