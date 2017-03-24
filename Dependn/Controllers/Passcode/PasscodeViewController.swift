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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        launchPasscode()
    }
    
    fileprivate func launchPasscode() {
        if let policy = PasscodeViewController.supportedOwnerAuthentications().first {
            authContext.evaluatePolicy(policy, localizedReason: L("passcode.reason")) { success, error in
                if success {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    DDLogError(error.debugDescription)
                    DispatchQueue.main.async(execute: self.launchPasscode)
                }
            }
        }
    }
    
    static func supportedOwnerAuthentications() -> [LAPolicy] {
        var supportedAuthentications = [LAPolicy]()
        var error: NSError?
        if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            supportedAuthentications.append(.deviceOwnerAuthenticationWithBiometrics)
        }
        DDLogError(error.debugDescription)
        if authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            supportedAuthentications.append(.deviceOwnerAuthentication)
        }
        DDLogError(error.debugDescription)
        return supportedAuthentications
    }

}
