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
    
    internal let dateFormatter = NSDateFormatter()
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        dateFormatter.dateFormat = "dd MMMM"
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        refreshInterface()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(GlanceInterfaceController.contextDidUpdate(_:)),
            name: kWatchExtensionContextUpdatedNotificationName,
            object: nil)
        
        WatchSessionManager.sharedManager.requestContext()
    }
    
    private func refreshInterface() {
        if let stats = WatchSessionManager.sharedManager.context.stats {
            if let value = stats.values.first {
                valueLbl.setText(value.value)
            }
            addictionLbl.setText(stats.addiction)
            
            let date = stats.values[0].date
            let proximity = SHDateProximityToDate(date)
            switch proximity {
            case .Today:
                dayLbl.setText(NSLocalizedString("watch.today", comment: ""))
            case .Yesterday:
                dayLbl.setText(NSLocalizedString("watch.yesterday", comment: ""))
            default:
                dayLbl.setText(dateFormatter.stringFromDate(date))
            }
            
            if let sinceLast = stats.sinceLast {
                let str = String(format: NSLocalizedString("watch.sinceLast", comment: ""), sinceLast)
                sinceLastLbl.setText(str)
            }
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func contextDidUpdate(notification: NSNotification) {
        refreshInterface()
    }

}
