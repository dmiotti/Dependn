//
//  PlaceListInterfaceController.swift
//  Dependn
//
//  Created by David Miotti on 28/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation


final class PlaceListInterfaceController: WKInterfaceController {
    
    @IBOutlet var table: WKInterfaceTable!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        let places = WatchSessionManager.sharedManager.context.places
        
        table.setNumberOfRows(places.count, withRowType: "DefaultTableRowController")
        
        for (index, add) in places.enumerated() {
            let row = table.rowController(at: index) as! DefaultTableRowController
            row.titleLbl.setText(add.name)
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let place = WatchSessionManager.sharedManager.context.places[rowIndex]
        WatchSessionManager.sharedManager.newRecordModel.place = place
        dismiss()
    }

}
