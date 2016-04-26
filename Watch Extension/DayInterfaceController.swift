//
//  DayInterfaceController.swift
//  Dependn
//
//  Created by David Miotti on 26/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit

class DayInterfaceController: WKInterfaceController {
    
    @IBOutlet var statsTable: WKInterfaceTable!
    
    let dateFormatter = NSDateFormatter()
    
    override init() {
        dateFormatter.dateFormat = "dd MMMM"
    }
    
    private func loadTableData(dataSource: [WatchStatsAddiction]) {
        statsTable.setNumberOfRows(dataSource.count, withRowType: "StatsTableRowController")
        
        for (index, element) in dataSource.enumerate() {
            if let row = statsTable.rowControllerAtIndex(index) as? StatsTableRowController {
                configureRow(row, withElement: element)
            }
        }
    }
    
    func configureRow(row: StatsTableRowController, withElement element: WatchStatsAddiction) {
        
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        
        addMenuItemWithItemIcon(.Play, title: NSLocalizedString("Conso", comment: ""), action: #selector(DayInterfaceController.doMenuAddConso))
        addMenuItemWithItemIcon(.Mute, title: NSLocalizedString("Craving", comment: ""), action: #selector(DayInterfaceController.doMenuAddCraving))
    }
    
    override func willActivate() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TodayInterfaceController.statsGetUpdated(_:)), name: kWatchExtensionStatsUpdatedNotificationName, object: nil)
        
        if let cached = CoreStack.shared.cachedStats {
            loadTableData(cached)
        }
        
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func statsGetUpdated(notification: NSNotification) {
        if let stats = notification.userInfo?["stats"] as? [WatchStatsAddiction] {
            dispatch_async(dispatch_get_main_queue()) {
                self.loadTableData(stats)
            }
        }
    }
    
    // MARK: Menu actions
    
    @IBAction func doMenuAddConso() {
        presentControllerWithName("AddictionList", context: nil)
    }
    
    @IBAction func doMenuAddCraving() {
        presentControllerWithName("AddictionList", context: nil)
    }
}