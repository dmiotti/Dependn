//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by David Miotti on 13/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController {
    
    @IBOutlet var statsTable: WKInterfaceTable!
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
            }
        }
    }
    
    private func loadTableData(dataSource: [Dictionary<String, AnyObject>]) {
        statsTable.setNumberOfRows(dataSource.count, withRowType: "StatsTableRowController")
        
        for (index, data) in dataSource.enumerate() {
            if let row = statsTable.rowControllerAtIndex(index) as? StatsTableRowController {
                if let name = data["name"] as? String {
                    row.addictionLbl.setText(name)
                }
                if let today = data["today"] as? Int {
                    row.todayValueLbl.setText("\(today)")
                }
                if let thisweek = data["thisweek"] as? Int {
                    row.thisWeekValueLbl.setText("\(thisweek)")
                }
                if let sincelast = data["sincelast"] as? NSTimeInterval {
                    row.sinceLastValueLbl.setText("\(sincelast)s")
                }
            }
        }
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
            session?.sendMessage(["action": "stats"], replyHandler: { (response) in
                if let values = response["stats"] as? [Dictionary<String, AnyObject>] {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.loadTableData(values)
                    }
                }
                }, errorHandler: { (err) in
                    print(err)
            })
        }
        
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

extension InterfaceController: WCSessionDelegate {
    
}
