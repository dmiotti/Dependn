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
    
    internal let dateFormatter = DateFormatter()
    
    func loadData(data: WatchStatsAddiction) { }
    
    override init() {
        dateFormatter.dateFormat = "d MMMM"
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        setTitle(NSLocalizedString("appname", comment: ""))
        
        addMenuItem(
            withImageNamed: "addIcon",
            title: NSLocalizedString("add.conso", comment: ""),
            action: #selector(DayInterfaceController.doMenuAddConso))
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(DayInterfaceController.contextDidUpdate(_:)),
            name: Notification.Name.WatchExtensionContextUpdatedNotificationName,
            object: nil)
        
        // Configure interface objects here.
        if let data = WatchSessionManager.sharedManager.context.stats {
            loadData(data: data)
        } else {
            valueLbl.setText(nil)
            addictionLbl.setText(nil)
            dayLbl.setText(nil)
        }
    }
    
    override func didDeactivate() {
        NotificationCenter.default.removeObserver(self)

        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func contextDidUpdate(_ notification: NSNotification) {
        if let context = notification.userInfo?["context"] as? AppContext, let stats = context.stats {
            loadData(data: stats)
        }
    }
    
    // MARK: Menu actions
    
    @IBAction func doMenuAddConso() {
        WatchSessionManager.sharedManager.newRecordModel.type = .Conso
        presentController(withName: "NewRecord", context: nil)
    }
    
    @IBAction func doMenuAddCraving() {
        WatchSessionManager.sharedManager.newRecordModel.type = .Craving
        presentController(withName: "NewRecord", context: nil)
    }
}
