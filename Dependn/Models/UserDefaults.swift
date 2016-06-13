//
//  UserDefaults.swift
//  Dependn
//
//  Created by David Miotti on 05/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

struct NotificationTypes: OptionSetType {
    let rawValue : Int
    init(rawValue: Int){
        self.rawValue = rawValue
    }
    init() {
        self = NotificationTypes.Empty
    }
    static let Empty    = NotificationTypes(rawValue: 0b0000)
    static let Daily    = NotificationTypes(rawValue: 0b0010)
    static let Weekly   = NotificationTypes(rawValue: 0b0100)
}

extension DefaultsKeys {
    static let alreadyLaunched           = DefaultsKey<Bool>("alreadyLaunched")
    static let usePasscode               = DefaultsKey<Bool>("usePasscode")
    static let useLocation               = DefaultsKey<Bool>("useLocation")
    static let hasSeenEmotionPlaceholder = DefaultsKey<Bool>("emotionPlaceholderSeen")
    static let initialPlacesImported     = DefaultsKey<Bool>("initialPlacesImported")
    static let watchAddiction            = DefaultsKey<String?>("watchAddiction")
    static let notificationTypes         = DefaultsKey<Int>("notificationTypes")
    static let pushAlreadyShown          = DefaultsKey<Bool>("pushAlreadyShown")
}
