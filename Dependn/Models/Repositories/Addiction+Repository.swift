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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


extension Addiction {
    
    class func findOrInsertNewAddiction(_ name: String, inContext context: NSManagedObjectContext) throws -> Addiction {
        if let dbAdd = try findByName(name, inContext: context) {
            return dbAdd
        }
        
        let newAdd = NSEntityDescription.insertNewObject(forEntityName: Addiction.entityName, into: context) as! Addiction
        newAdd.name = name
        newAdd.color = UIColor.randomFlat.hexValue()
         
        if Defaults[.watchAddiction] == nil {
           Defaults[.watchAddiction] = name
        }
        
        WatchSessionManager.sharedManager.updateApplicationContext()
        
        return newAdd
    }
    
    static func findByName(_ name: String, inContext context: NSManagedObjectContext) throws -> Addiction? {
        let req = entityFetchRequest()
        req.predicate = NSPredicate(format: "name ==[cd] %@", name)
        req.fetchLimit = 1
        return try context.fetch(req).first
    }
    
    class func getAllAddictions(inContext context: NSManagedObjectContext) throws -> [Addiction] {
        let req = entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        return try context.fetch(req)
    }
    
    class func getAllAddictionsOrderedByCount(inContext context: NSManagedObjectContext) throws -> [Addiction] {
        let req = entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        var addictions = try context.fetch(req)
        addictions.sort { $0.records?.count > $1.records?.count }
        return addictions
    }
    
    class func deleteAddiction(_ addiction: Addiction, inContext context: NSManagedObjectContext) throws {
        if Defaults[.watchAddiction] == addiction.name {
           Defaults[.watchAddiction] = nil
        }
        
        let records = try Record.recordForAddiction(addiction, inContext: context)
        
        for record in records {
            context.delete(record)
        }
        context.delete(addiction)
    }
    
}
