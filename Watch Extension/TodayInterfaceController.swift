//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by David Miotti on 13/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit

final class TodayInterfaceController: DayInterfaceController {
    
    override func awakeWithContext(context: Any?) {
        super.awake(withContext: context)
        
        becomeCurrentPage()
    }
    
    override func loadData(data: WatchStatsAddiction) {
        super.loadData(data: data)
        
        let value = data.values[0]
        valueLbl.setText(value.value)
        addictionLbl.setText(data.addiction)
        dayLbl.setText(value.date)
        
        setTitle(data.formattedSinceLast)
    }
    
}
