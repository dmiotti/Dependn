//
//  MainInterfaceController.swift
//  Dependn
//
//  Created by David Miotti on 27/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation

final class InfoInterfaceController: WKInterfaceController {
    
    @IBOutlet var infoLbl: WKInterfaceLabel!
    @IBOutlet var descriptionLbl: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        if let error = context as? NSError {
            infoLbl.setText(error.localizedDescription)
            descriptionLbl.setText(error.localizedRecoverySuggestion)
        } else {
            infoLbl.setText(NSLocalizedString("watch.loading", comment: ""))
            descriptionLbl.setText(NSLocalizedString("watch.loading.pleasewait", comment: ""))
        }
    }
    
    override func willActivate() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self,
                       selector: #selector(InfoInterfaceController.statsGetUpdated(_:)),
                       name: kWatchExtensionStatsUpdatedNotificationName,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(InfoInterfaceController.statsGetError(_:)),
                       name: kWatchExtensionStatsUpdatedNotificationName,
                       object: nil)
        
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func statsGetUpdated(notification: NSNotification) {
        if let _ = notification.userInfo?["stats"] as? WatchStatsAddiction {
            dispatch_async(dispatch_get_main_queue()) {
                WKInterfaceController.reloadRootControllersWithNames([
                    "TodayInterfaceController",
                    "YesterdayInterfaceController",
                    "TwoDaysAgoInterfaceController",
                    "ThreeDaysAgoInterfaceController"
                    ], contexts: nil)
            }
        }
    }
    
    func statsGetError(notification: NSNotification) {
        if let err = notification.userInfo?["error"] as? NSError {
            dispatch_async(dispatch_get_main_queue()) {
                self.infoLbl.setText(err.localizedDescription)
                self.descriptionLbl.setText(err.localizedRecoverySuggestion)
            }
        }
    }
    
}
