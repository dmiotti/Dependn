//
//  TwoDaysAgoInterfaceController.swift
//  Dependn
//
//  Created by David Miotti on 25/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation

class TwoDaysAgoInterfaceController: DayInterfaceController {
    
    override func configureRow(row: StatsTableRowController, withElement element: WatchStatsAddiction) {
        row.addictionLbl.setText(element.addiction)
        
        if element.values.count > 1 {
            let value = element.values[2]
            let date = dateFormatter.stringFromDate(value.date)
            row.dateLbl.setText(date)
            row.valueLbl.setText(value.value)
        }
    }
    
}
