//
//  IntensityChooserInterfaceController.swift
//  Dependn
//
//  Created by David Miotti on 30/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation


final class IntensityChooserInterfaceController: WKInterfaceController {

    @IBOutlet var intensityPicker: WKInterfacePicker!
    
    @IBOutlet var validateBtn: WKInterfaceButton!
    
    private let values: [Int] = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    
    private var selectedIntensity = Int(WatchSessionManager.sharedManager.newRecordModel.intensity)
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        validateBtn.setTitle(NSLocalizedString("intensity.select", comment: ""))
        
        // Configure interface objects here.
        let percentImages = values.map { "intensity\($0)circle" }
        let pickerItems: [WKPickerItem] = percentImages.map {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: $0)
            return item
        }
        intensityPicker.setItems(pickerItems)
        intensityPicker.focus()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        
        if let idx = values.index(of: selectedIntensity) {
            intensityPicker.setSelectedItemIndex(idx)
        } else {
            intensityPicker.setSelectedItemIndex(7)
        }
        
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func intensityValueChanged(value: Int) {
        selectedIntensity = values[value]
    }

    @IBAction func validateBtnClicked() {
        WatchSessionManager.sharedManager.newRecordModel.intensity = Float(selectedIntensity)
        dismiss()
    }
}
