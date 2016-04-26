//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by David Miotti on 13/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit

class TodayInterfaceController: DayInterfaceController {
    
    override func configureRow(row: StatsTableRowController, withElement element: WatchStatsAddiction) {
        row.addictionLbl.setText(element.addiction)
        
        if let value = element.values.first {
            let date = dateFormatter.stringFromDate(value.date)
            row.dateLbl.setText(date)
            row.valueLbl.setText(value.value)
        }
    }
    
}
