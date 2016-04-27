//
//  DayInterfaceController.swift
//  Dependn
//
//  Created by David Miotti on 26/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit

class DayInterfaceController: WKInterfaceController {
    
    @IBOutlet var valueLbl: WKInterfaceLabel!
    @IBOutlet var addictionLbl: WKInterfaceLabel!
    @IBOutlet var dayLbl: WKInterfaceLabel!
    
    let dateFormatter = NSDateFormatter()
    
    func loadData(data: WatchStatsAddiction) { }
    
    override init() {
        dateFormatter.dateFormat = "dd MMMM"
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        if let cached = CoreStack.shared.cachedStats {
            self.loadData(cached)
        } else {
            valueLbl.setText(nil)
            addictionLbl.setText(NSLocalizedString("watch.loading", comment: ""))
            dayLbl.setText(NSLocalizedString("watch.loading.pleasewait", comment: ""))
        }
        
        addMenuItemWithItemIcon(.Play,
                                title: NSLocalizedString("Conso", comment: ""),
                                action: #selector(DayInterfaceController.doMenuAddConso))
        addMenuItemWithItemIcon(.Mute,
                                title: NSLocalizedString("Craving", comment: ""),
                                action: #selector(DayInterfaceController.doMenuAddCraving))
    }
    
    override func willActivate() {
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(TodayInterfaceController.statsGetUpdated(_:)),
                                                         name: kWatchExtensionStatsUpdatedNotificationName,
                                                         object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(TodayInterfaceController.statsGetError(_:)),
                                                         name: kWatchExtensionStatsErrorNotificationName,
                                                         object: nil)
        
        if let cached = CoreStack.shared.cachedStats {
            loadData(cached)
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
        if let stats = notification.userInfo?["stats"] as? WatchStatsAddiction {
            dispatch_async(dispatch_get_main_queue()) {
                self.loadData(stats)
            }
        }
    }
    
    func statsGetError(notification: NSNotification) {
        if let error = notification.userInfo?["error"] as? NSError {
            dispatch_async(dispatch_get_main_queue()) {
                WKInterfaceController.reloadRootControllersWithNames([
                    "InfoInterfaceController"], contexts: [error])
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
