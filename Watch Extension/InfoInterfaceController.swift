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
        
        if let context = context as? Dictionary<String, String> {
            if let info = context["info"] {
                infoLbl.setText(info)
            }
            if let desc = context["desc"] {
                descriptionLbl.setText(desc)
            }
        } else {
            infoLbl.setText(NSLocalizedString("watch.loading", comment: ""))
            descriptionLbl.setText(NSLocalizedString("watch.loading.pleasewait", comment: ""))
        }
    }
    
    override func willActivate() {
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(InfoInterfaceController.contextDidFail(_:)),
            name: kWatchExtensionContextErrorNotificationName,
            object: nil)
        
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func contextDidFail(notification: NSNotification) {
        if let err = notification.userInfo?["error"] as? NSError {
            dispatch_async(dispatch_get_main_queue()) {
                self.infoLbl.setText(err.localizedDescription)
                self.descriptionLbl.setText(err.localizedRecoverySuggestion)
            }
        }
    }
    
}
