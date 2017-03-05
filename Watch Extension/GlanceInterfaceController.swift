//
//  GlanceInterfaceController.swift
//  Dependn
//
//  Created by David Miotti on 28/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation

final class GlanceInterfaceController: WKInterfaceController {

    @IBOutlet var valueLbl: WKInterfaceLabel!
    @IBOutlet var addictionLbl: WKInterfaceLabel!
    @IBOutlet var dayLbl: WKInterfaceLabel!
    @IBOutlet var sinceLastLbl: WKInterfaceLabel!
    
    internal let dateFormatter = DateFormatter()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        dateFormatter.dateFormat = "dd MMMM"
        
        WatchSessionManager.sharedManager.startSession()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        refreshInterface()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(GlanceInterfaceController.contextDidUpdate(_:)),
            name: Notification.Name.WatchExtensionContextUpdatedNotificationName,
            object: nil)
        
        WatchSessionManager.sharedManager.requestContext()
    }
    
    private func refreshInterface() {
        if let stats = WatchSessionManager.sharedManager.context.stats {
            
            if let value = stats.values.first {
                valueLbl.setText(value.value)
                dayLbl.setText(value.date)
            }
            
            addictionLbl.setText(stats.addiction)
            sinceLastLbl.setText(stats.formattedSinceLast)
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func contextDidUpdate(_ notification: NSNotification) {
        refreshInterface()
    }

}
