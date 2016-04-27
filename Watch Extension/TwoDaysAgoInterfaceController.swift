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
        super.loadData(data)
        
        addictionLbl.setText(data.addiction)
        valueLbl.setText(data.values[2].value)
        
        let date = data.values[2].date
        let proximity = SHDateProximityToDate(date)
        switch proximity {
        case .Today:
            dayLbl.setText(NSLocalizedString("watch.today", comment: ""))
        case .Yesterday:
            dayLbl.setText(NSLocalizedString("watch.yesterday", comment: ""))
        default:
            dayLbl.setText(dateFormatter.stringFromDate(date))
        }
    }
    
}
