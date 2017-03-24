//
//  NewRecordInterfaceController.swift
//  Dependn
//
//  Created by David Miotti on 28/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation

enum NewRecordRowType: Int {
    case addiction
    case place
    case intensity
    
    static let count: Int = {
        var max: Int = 0
        while let _ = NewRecordRowType(rawValue: max) { max += 1 }
        return max
    }()
}

final class NewRecordInterfaceController: WKInterfaceController {
    
    @IBOutlet var table: WKInterfaceTable!
    @IBOutlet var addBtn: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        addBtn.setTitle(NSLocalizedString("new_record.add", comment: ""))
        
        /// Prepare interface with default values
        let manager = WatchSessionManager.sharedManager
        let appContext = manager.context
        let places = appContext.places
        let addictions = appContext.addictions
        let mostUsedAddiction = appContext.mostUsedAddiction ?? addictions.first
        let mostUsedPlace = appContext.mostUsedPlace ?? places.first
        
        let newRecordModel = manager.newRecordModel
        newRecordModel.addiction = mostUsedAddiction
        newRecordModel.place = mostUsedPlace
        newRecordModel.intensity = 7
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let newRecordModel = WatchSessionManager.sharedManager.newRecordModel
        
        let selectedAddiction = newRecordModel.addiction
        let selectedPlace = newRecordModel.place
        let selectedIntensity = newRecordModel.intensity
        
        table.setNumberOfRows(NewRecordRowType.count, withRowType: "TitleValueTableRowController")
        
        for idx in 0..<NewRecordRowType.count {
            let rowCtrl = table.rowController(at: idx) as! TitleValueTableRowController
            
            let row = NewRecordRowType(rawValue: idx)!
            
            rowCtrl.titleLbl.setText(nil)
            
            switch row {
            case .addiction:
                if let selectedAddiction = selectedAddiction {
                    rowCtrl.valueLbl.setText(selectedAddiction.name)
                } else {
                    rowCtrl.valueLbl.setText(nil)
                }
            case .place:
                if let selectedPlace = selectedPlace {
                    rowCtrl.valueLbl.setText(selectedPlace.name)
                } else {
                    rowCtrl.valueLbl.setText(nil)
                }
            case .intensity:
                let roundedIntensity = Int(round(selectedIntensity))
                rowCtrl.valueLbl.setText("\(roundedIntensity)")
                rowCtrl.valueLbl.setTextColor(.white)
            }
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if let row = NewRecordRowType(rawValue: rowIndex) {
            switch row {
            case .addiction:
                presentController(withName: "AddictionList", context: nil)
            case .place:
                presentController(withName: "PlaceList", context: nil)
            case .intensity:
                presentController(withName: "IntensityChooser", context: nil)
            }
        }
    }

    @IBAction func addBtnClicked() {
        WatchSessionManager.sharedManager.sendAdd()
        dismiss()
    }
}
