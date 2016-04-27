//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by David Miotti on 13/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit

final class TodayInterfaceController: DayInterfaceController {
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        becomeCurrentPage()
    }
    
    override func loadData(data: WatchStatsAddiction) {
        super.loadData(data)
        
        addictionLbl.setText(data.addiction)
        valueLbl.setText(data.values[0].value)
        
        let date = data.values[0].date
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
