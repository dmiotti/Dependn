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
    static let alreadyLaunched = DefaultsKey<Bool>("alreadyLaunched")
    static let usePasscode = DefaultsKey<Bool>("usePasscode")
    static let useLocation = DefaultsKey<Bool>("useLocation")
    static let hasSeenEmotionPlaceholder = DefaultsKey<Bool>("emotionPlaceholderSeen")
    static let initialPlacesImported = DefaultsKey<Bool>("initialPlacesImported")
    static let watchAddiction = DefaultsKey<String?>("watchAddiction")
}
