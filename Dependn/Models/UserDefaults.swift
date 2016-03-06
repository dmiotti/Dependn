//
//  UserDefaults.swift
//  Dependn
//
//  Created by David Miotti on 05/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

extension DefaultsKeys {
    static let usePasscode = DefaultsKey<Bool>("usePasscode")
    static let passcode = DefaultsKey<String?>("passcode")
}
