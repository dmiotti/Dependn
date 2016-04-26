//
//  ThreeDaysAgoInterfaceController.swift
//  Dependn
//
//  Created by David Miotti on 25/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation

class ThreeDaysAgoInterfaceController: DayInterfaceController {
    
    override func configureRow(row: StatsTableRowController, withElement element: WatchStatsAddiction) {
        row.addictionLbl.setText(element.addiction)
        
        if element.values.count > 2 {
            let value = element.values[3]
            let date = dateFormatter.stringFromDate(value.date)
            row.dateLbl.setText(date)
            row.valueLbl.setText(value.value)
        }
    }

}
