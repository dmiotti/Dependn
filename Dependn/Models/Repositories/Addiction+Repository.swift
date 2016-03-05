//
//  Addiction+Repository.swift
//  Dependn
//
//  Created by David Miotti on 05/03/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import Foundation
import CoreData
import ChameleonFramework

extension Addiction {
    
    class func findOrInsertNewAddiction(name: String, inContext context: NSManagedObjectContext) throws -> Addiction {
        let req = entityFetchRequest()
        req.predicate = NSPredicate(format: "name ==[cd] %@", name)
        req.fetchLimit = 1

        if let dbAdd = try context.executeFetchRequest(req).last as? Addiction {
            return dbAdd
        }
        
        let newAdd = NSEntityDescription.insertNewObjectForEntityForName(Addiction.entityName, inManagedObjectContext: context) as! Addiction
        newAdd.name = name.lowercaseString
        newAdd.color = UIColor.randomFlatColor().hexValue()
        return newAdd
    }
    
    class func getAllAddictions(inContext context: NSManagedObjectContext) throws -> [Addiction] {
        let req = entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        return try context.executeFetchRequest(req) as? [Addiction] ?? []
    }
    
    class func deleteAddiction(addiction: Addiction, inContext context: NSManagedObjectContext) throws {
        let records = try Record.recordForAddiction(addiction, inContext: context)
        for record in records {
            context.deleteObject(record)
        }
        context.deleteObject(addiction)
    }
    
}