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
    case Addiction
    case Place
    case Intensity
    
    static let count: Int = {
        var max: Int = 0
        while let _ = NewRecordRowType(rawValue: max) { max += 1 }
        return max
    }()
}

final class NewRecordInterfaceController: WKInterfaceController {
    
    @IBOutlet var table: WKInterfaceTable!
    @IBOutlet var addBtn: WKInterfaceButton!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
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
        
        table.setNumberOfRows(NewRecordRowType.count, withRowType: "DefaultTableRowController")
        
        for idx in 0..<NewRecordRowType.count {
            let rowCtrl = table.rowControllerAtIndex(idx) as! DefaultTableRowController
            
            let row = NewRecordRowType(rawValue: idx)!
            switch row {
            case .Addiction:
                if let selectedAddiction = selectedAddiction {
                    rowCtrl.titleLbl.setText(selectedAddiction.name)
                    rowCtrl.titleLbl.setTextColor(UIColor.whiteColor())
                } else {
                    rowCtrl.titleLbl.setText(NSLocalizedString("new_record.addiction", comment: ""))
                    rowCtrl.titleLbl.setTextColor(UIColor.lightGrayColor())
                }
            case .Place:
                if let selectedPlace = selectedPlace {
                    rowCtrl.titleLbl.setText(selectedPlace.name)
                    rowCtrl.titleLbl.setTextColor(UIColor.whiteColor())
                } else {
                    rowCtrl.titleLbl.setText(NSLocalizedString("new_record.place", comment: ""))
                    rowCtrl.titleLbl.setTextColor(UIColor.lightGrayColor())
                }
            case .Intensity:
                let roundedIntensity = Int(round(selectedIntensity))
                rowCtrl.titleLbl.setText("\(roundedIntensity)")
                rowCtrl.titleLbl.setTextColor(UIColor.whiteColor())
            }
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        if let row = NewRecordRowType(rawValue: rowIndex) {
            switch row {
            case .Addiction:
                presentControllerWithName("AddictionList", context: nil)
            case .Place:
                presentControllerWithName("PlaceList", context: nil)
            case .Intensity:
                break
            }
        }
    }

    @IBAction func addBtnClicked() {
        WatchSessionManager.sharedManager.sendAdd()
        dismissController()
    }
}
