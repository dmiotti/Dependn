//
//  Smoke.swift
//  Dependn
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import CoreData

enum SmokeType {
    case Cig, Weed
}

let SmokeTypeCig = "Cig"
let SmokeTypeWeed = "Weed"

final class Smoke: NSManagedObject, NamedEntity {
    
    static let sectionDateFormatter = NSDateFormatter(dateFormat: "EEEE dd MMMM yyyy")
    
    static var entityName: String { get { return "Smoke" } }
    
    var smokeType: SmokeType {
        get {
            return type == SmokeTypeCig ? .Cig : .Weed
        }
        set {
            if newValue == .Cig {
                type = SmokeTypeCig
            } else {
                type = SmokeTypeWeed
            }
        }
    }
    
    var sectionIdentifier: String? {
        return Smoke.sectionDateFormatter.stringFromDate(date)
    }
    
}
