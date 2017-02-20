//
//  TwoDaysAgoInterfaceController.swift
//  Dependn
//
//  Created by David Miotti on 25/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation

final class TwoDaysAgoInterfaceController: DayInterfaceController {
    
    override func loadData(data: WatchStatsAddiction) {
        super.loadData(data: data)
        let value = data.values[2]
        valueLbl.setText(value.value)
        addictionLbl.setText(data.addiction)
        dayLbl.setText(value.date)
    }
    
}
