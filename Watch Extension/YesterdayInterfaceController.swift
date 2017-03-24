//
//  ExtasyICInterfaceController.swift
//  Dependn
//
//  Created by David Miotti on 25/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation

final class YesterdayInterfaceController: DayInterfaceController {
    
    override func loadData(_ data: WatchStatsAddiction) {
        super.loadData(data)
        
        let value = data.values[1]
        valueLbl.setText(value.value)
        addictionLbl.setText(data.addiction)
        dayLbl.setText(value.date)
    }
    
}
