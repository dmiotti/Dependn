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
    
    let url: URL
    
    fileprivate let components: URLComponents
    fileprivate let context: UIViewController
    
    init(url: URL, inContext context: UIViewController) {
        self.url = url
        self.components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        self.context = context
    }
    
    func execute() {
        if let scheme = components.scheme, scheme == "http" || scheme == "https" {
            UIApplication.shared.open(url, options: [:])
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
    
    fileprivate func doAdd() {
        if ensureThereIsAddictions() {
            let nav = SHStatusBarNavigationController(rootViewController: AddRecordViewController())
            nav.statusBarStyle = .default
            nav.modalPresentationStyle = .formSheet
            context.present(nav, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: L("history.no_addictions.title"), message: L("history.no_addictions.message"), preferredStyle: .alert)
            let addAction = UIAlertAction(title: L("history.no_addictions.add"), style: .default) { action in
                let controller = AddictionListViewController()
                if let nav = self.context.navigationController {
                    nav.pushViewController(controller, animated: true)
                } else {
                    self.context.present(controller, animated: true, completion: nil)
                }
            }
            let okAction = UIAlertAction(title: L("history.no_addictions.ok"), style: .cancel, handler: nil)
            alert.addAction(addAction)
            alert.addAction(okAction)
            context.present(alert, animated: true, completion: nil)
        }
        
    }
    
    fileprivate func ensureThereIsAddictions() -> Bool {
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
        if let url = URL(string: URLString) {
            let manager = DeeplinkManager(url: url, inContext: context)
            manager.execute()
        }
    }

}
