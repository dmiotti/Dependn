//
//  ThreeDaysAgoInterfaceController.swift
//  Dependn
//
//  Created by David Miotti on 25/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation

final class ThreeDaysAgoInterfaceController: DayInterfaceController {
    
    override func loadData(data: WatchStatsAddiction) {
        super.loadData(data)
        
        let value = data.values[3]
        valueLbl.setText(value.value)
        addictionLbl.setText(data.addiction)
        dayLbl.setText(value.date)
    }

}
