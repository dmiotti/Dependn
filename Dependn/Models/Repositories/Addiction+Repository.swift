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
import SwiftyUserDefaults

extension Addiction {
    
    class func findOrInsertNewAddiction(name: String, inContext context: NSManagedObjectContext) throws -> Addiction {
        if let dbAdd = try findByName(name, inContext: context) {
            return dbAdd
        }
        
        let newAdd = NSEntityDescription.insertNewObjectForEntityForName(Addiction.entityName, inManagedObjectContext: context) as! Addiction
        newAdd.name = name
        newAdd.color = UIColor.randomFlatColor().hexValue()
         
        if Defaults[.watchAddiction] == nil {
           Defaults[.watchAddiction] = name
        }
        
        return newAdd
    }
    
    static func findByName(name: String, inContext context: NSManagedObjectContext) throws -> Addiction? {
        let req = entityFetchRequest()
        req.predicate = NSPredicate(format: "name ==[cd] %@", name)
        req.fetchLimit = 1
        return try context.executeFetchRequest(req).first as? Addiction
    }
    
    class func getAllAddictions(inContext context: NSManagedObjectContext) throws -> [Addiction] {
        let req = entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        return try context.executeFetchRequest(req) as? [Addiction] ?? []
    }
    
    class func getAllAddictionsOrderedByCount(inContext context: NSManagedObjectContext) throws -> [Addiction] {
        let req = entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        var addictions = try context.executeFetchRequest(req) as? [Addiction] ?? [Addiction]()
        addictions.sortInPlace { (a, b) -> Bool in
            return a.records?.count > b.records?.count
        }
        return addictions
    }
    
    class func deleteAddiction(addiction: Addiction, inContext context: NSManagedObjectContext) throws {
        if Defaults[.watchAddiction] == addiction.name {
           Defaults[.watchAddiction] = nil
        }
        
        let records = try Record.recordForAddiction(addiction, inContext: context)
        
        for record in records {
            context.deleteObject(record)
        }
        context.deleteObject(addiction)
    }
    
}