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
    
    internal let dateFormatter = NSDateFormatter()
    
    func loadData(data: WatchStatsAddiction) { }
    
    override init() {
        dateFormatter.dateFormat = "dd MMMM"
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        setTitle(NSLocalizedString("appname", comment: ""))
        
        addMenuItemWithItemIcon(
            .Play,
            title: NSLocalizedString("Conso", comment: ""),
            action: #selector(DayInterfaceController.doMenuAddConso))
        addMenuItemWithItemIcon(
            .Mute,
            title: NSLocalizedString("Craving", comment: ""),
            action: #selector(DayInterfaceController.doMenuAddCraving))
    }
    
    override func willActivate() {
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(DayInterfaceController.contextDidUpdate(_:)),
            name: kWatchExtensionContextUpdatedNotificationName,
            object: nil)
        
        // Configure interface objects here.
        if let data = WatchSessionManager.sharedManager.context.stats {
            loadData(data)
        } else {
            valueLbl.setText(nil)
            addictionLbl.setText(nil)
            dayLbl.setText(nil)
        }
        
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func contextDidUpdate(notification: NSNotification) {
        if let context = notification.userInfo?["context"] as? AppContext, stats = context.stats {
            loadData(stats)
        }
    }
    
    // MARK: Menu actions
    
    @IBAction func doMenuAddConso() {
        WatchSessionManager.sharedManager.newEntryData["type"] = "conso"
        presentControllerWithName("NewRecord", context: nil)
    }
    
    @IBAction func doMenuAddCraving() {
        WatchSessionManager.sharedManager.newEntryData["type"] = "craving"
        presentControllerWithName("NewRecord", context: nil)
    }
}
