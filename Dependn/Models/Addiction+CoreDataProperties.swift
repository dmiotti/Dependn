//
//  Addiction+CoreDataProperties.swift
//  Dependn
//
//  Created by David Miotti on 05/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Addiction {

    @NSManaged var name: String
    @NSManaged var color: String
    @NSManaged var records: NSSet?

}
