//
//  AddictionListInterfaceController.swift
//  Dependn
//
//  Created by David Miotti on 26/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation

final class AddictionListInterfaceController: WKInterfaceController {

    @IBOutlet var table: WKInterfaceTable!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        
        let addictions = WatchSessionManager.sharedManager.context.addictions
        
        table.setNumberOfRows(addictions.count, withRowType: "DefaultTableRowController")
        
        for (index, add) in addictions.enumerated() {
            let row = table.rowController(at: index) as! DefaultTableRowController
            row.titleLbl.setText(add.name)
        }
        
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let manager = WatchSessionManager.sharedManager
        let addiction = manager.context.addictions[rowIndex]
        manager.newRecordModel.addiction = addiction
        dismiss()
    }

}
