//
//  Place+CoreDataProperties.swift
//  SmokeReporter
//
//  Created by David Miotti on 25/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Place {

    @NSManaged var lat: NSNumber
    @NSManaged var lon: NSNumber
    @NSManaged var name: String?
    @NSManaged var smokes: NSSet?

}
