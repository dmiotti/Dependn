//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by David Miotti on 13/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    
    @IBOutlet var statsTable: WKInterfaceTable!
    
    let dataSource = [
        [
            "name": "Cigarette",
            "today": "10",
            "thisweek": "44",
            "sincelast": "4h"
        ],
        [
            "name": "Weed",
            "today": "10",
            "thisweek": "44",
            "sincelast": "4h"
        ]
    ]
    
    private func loadTableData() {
        statsTable.setNumberOfRows(dataSource.count, withRowType: "StatsTableRowController")
        
        for (index, data) in dataSource.enumerate() {
            if let row = statsTable.rowControllerAtIndex(index) as? StatsTableRowController {
                row.addictionLbl.setText(data["name"])
                row.todayValueLbl.setText(data["today"])
                row.thisWeekValueLbl.setText(data["thisweek"])
                row.sinceLastValueLbl.setText(data["sincelast"])
            }
        }
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        
        loadTableData()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
