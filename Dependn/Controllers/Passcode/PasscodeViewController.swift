//
//  HidingViewController.swift
//  Dependn
//
//  Created by David Miotti on 06/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import LocalAuthentication
import CocoaLumberjack
import SwiftyUserDefaults

private let authContext = LAContext()

final class PasscodeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.lightBackgroundColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        launchPasscode()
    }
    
    private func launchPasscode() {
        if let policy = PasscodeViewController.supportedOwnerAuthentications().first {
            authContext.evaluatePolicy(policy, localizedReason: L("passcode.reason")) { success, error in
                if success {
                    self.dismissViewControllerAnimated(true, completion: nil)
                } else {
                    DDLogError("\(error)")
                    dispatch_async(dispatch_get_main_queue()) {
                        self.launchPasscode()
                    }
                }
            }
        }
    }
    
    static func supportedOwnerAuthentications() -> [LAPolicy] {
        var supportedAuthentications = [LAPolicy]()
        var error: NSError?
        if authContext.canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            supportedAuthentications.append(.DeviceOwnerAuthenticationWithBiometrics)
        }
        DDLogError("\(error)")
        if authContext.canEvaluatePolicy(.DeviceOwnerAuthentication, error: &error) {
            supportedAuthentications.append(.DeviceOwnerAuthentication)
        }
        DDLogError("\(error)")
        return supportedAuthentications
    }

}
