//
//  NamedEntities.swift
//  SmokeReporter
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation

protocol NamedEntity {
    static var entityName: String { get }
}

extension Smoke: NamedEntity {
    static var entityName: String {
        get {
            return "Smoke"
        }
    }
}
