//
//  Place.swift
//  SmokeReporter
//
//  Created by David Miotti on 25/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import CoreData


final class Place: NSManagedObject, NamedEntity {
    
    static var entityName: String { get { return "Place" } }

}
