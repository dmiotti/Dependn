//
//  Record.swift
//  Dependn
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import CoreData

enum RecordType {
    case Cig, Weed
}

let kRecordTypeCig = "Cig"
let kRecordTypeWeed = "Weed"

final class Record: NSManagedObject, NamedEntity {
    
    static let sectionDateFormatter = NSDateFormatter(dateFormat: "EEEE dd MMMM yyyy")
    
    static var entityName: String { get { return "Record" } }
    
    var recordType: RecordType {
        get {
            return type == kRecordTypeCig ? .Cig : .Weed
        }
        set {
            if newValue == .Cig {
                type = kRecordTypeCig
            } else {
                type = kRecordTypeWeed
            }
        }
    }
    
    var sectionIdentifier: String? {
        return Record.sectionDateFormatter.stringFromDate(date)
    }
    
}
