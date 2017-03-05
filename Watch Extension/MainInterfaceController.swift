//
//  MainInterfaceController.swift
//  Dependn
//
//  Created by David Miotti on 27/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import WatchKit
import Foundation

final class MainInterfaceController: WKInterfaceController {
    
    @IBOutlet var infoLbl: WKInterfaceLabel!
    @IBOutlet var descriptionLbl: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        infoLbl.setText(NSLocalizedString("watch.loading", comment: ""))
        descriptionLbl.setText(NSLocalizedString("watch.loading.pleasewait", comment: ""))
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(MainInterfaceController.contextDidFail(_:)),
            name: Notification.Name.WatchExtensionContextErrorNotificationName,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(MainInterfaceController.contextDidUpdate(_:)),
            name: Notification.Name.WatchExtensionContextUpdatedNotificationName,
            object: nil)
    }
    
    override func willActivate() {
        
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func contextDidUpdate(_ notification: NSNotification) {
        if let context = notification.userInfo?["context"] as? AppContext, context.stats != nil {
            WKInterfaceController.reloadRootControllers(withNames: [
                "Today",
                "Yesterday",
                "TwoDaysAgo",
                "ThreeDaysAgo"
                ], contexts: nil)
            
            NotificationCenter.default.removeObserver(
                self,
                name: Notification.Name.WatchExtensionContextUpdatedNotificationName,
                object: nil)
            
            NotificationCenter.default.removeObserver(
                self,
                name: Notification.Name.WatchExtensionContextErrorNotificationName,
                object: nil)
        }
    }
    
    func contextDidFail(_ notification: NSNotification) {
        if let err = notification.userInfo?["error"] as? NSError {
            self.infoLbl.setText(err.localizedDescription)
            self.descriptionLbl.setText(err.localizedRecoverySuggestion)
        }
    }
    
}
