//
//  DeeplinkManager.swift
//  Dependn
//
//  Created by David Miotti on 01/05/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers

private let kDeeplinkAddEntryName = "addentry"

final class DeeplinkManager: NSObject {
    
    let URL: NSURL
    
    private let components: NSURLComponents
    private let context: UIViewController
    
    init(URL: NSURL, inContext context: UIViewController) {
        self.URL = URL
        self.components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)!
        self.context = context
    }
    
    func execute() {
        
        if let scheme = components.scheme where scheme == "http" || scheme == "https" {
            UIApplication.sharedApplication().openURL(URL)
            return
        }
        
        if let host = components.host {
            switch host {
            case kDeeplinkAddEntryName:
                doAdd()
            default:
                break
            }
        }
        
    }
    
    private func doAdd() {
        
        if ensureThereIsAddictions() {
            let nav = SHStatusBarNavigationController(rootViewController: AddRecordViewController())
            nav.statusBarStyle = .Default
            nav.modalPresentationStyle = .FormSheet
            context.presentViewController(nav, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: L("history.no_addictions.title"), message: L("history.no_addictions.message"), preferredStyle: .Alert)
            let addAction = UIAlertAction(title: L("history.no_addictions.add"), style: .Default) { action in
                let controller = AddictionListViewController()
                if let nav = self.context.navigationController {
                    nav.pushViewController(controller, animated: true)
                } else {
                    self.context.presentViewController(controller, animated: true, completion: nil)
                }
            }
            let okAction = UIAlertAction(title: L("history.no_addictions.ok"), style: .Cancel, handler: nil)
            alert.addAction(addAction)
            alert.addAction(okAction)
            context.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    private func ensureThereIsAddictions() -> Bool {
        var hasAddictions = false
        do {
            let moc = CoreDataStack.shared.managedObjectContext
            hasAddictions = try Addiction.getAllAddictions(inContext: moc).count > 0
        } catch let err as NSError {
            print("Error while checking there is at least one addiction: \(err)")
        }
        return hasAddictions
    }
    
    
    static func invokeAddEntry(inContext context: UIViewController) {
        let URLString = "dependn://\(kDeeplinkAddEntryName)"
        if let URL = NSURL(string: URLString) {
            let manager = DeeplinkManager(URL: URL, inContext: context)
            manager.execute()
        }
    }

}
