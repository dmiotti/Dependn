//
//  CoreDataStack.swift
//  Dependn
//
//  Created by David Miotti on 21/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import CoreData
import CocoaLumberjack
import SwiftHelpers

private let kCoreDataStackErrorDomain = "CoreDataStack"
private let kCoreDataStackMomdFilename = "Dependn"
private let kCoreDataStackSQLLiteFilename = "Dependn.sqlite"

protocol NamedEntity {
    static var entityName: String { get }
    static func entityFetchRequest() -> NSFetchRequest<NSFetchRequestResult>
}

extension NamedEntity {
    static func entityFetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: entityName)
    }
    static func insertEntity(inContext context: NSManagedObjectContext) -> Self {
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! Self
    }
}

let kCoreDataStackStoreWillChange = "CoreDataStackStoreWillChange"
let kCoreDataStackStoreDidChange = "CoreDataStackStoreDidChange"

final class CoreDataStack: NSObject {
    
    static let shared = CoreDataStack()
    
    override init() {
        super.init()
        
        registerNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.wopata.Dependn" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and loa,d its model.
        let modelURL = Bundle.main.url(forResource: kCoreDataStackMomdFilename, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent(kCoreDataStackSQLLiteFilename)
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            var opts = [String: Any]()
            opts[NSMigratePersistentStoresAutomaticallyOption] = true
            opts[NSInferMappingModelAutomaticallyOption] = true
            if !DeviceType.isSimulator {
                opts[NSPersistentStoreUbiquitousContentNameKey] = "Dependn"
            }
            opts[NSPersistentStoreFileProtectionKey] = FileProtectionType.completeUntilFirstUserAuthentication as AnyObject?
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: opts)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: kCoreDataStackErrorDomain, code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Handle CoreData notifications
    
    fileprivate func registerNotificationObservers() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(CoreDataStack.storesWillChange(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange, object: nil)
        nc.addObserver(self, selector: #selector(CoreDataStack.storesDidChange(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: nil)
        nc.addObserver(self, selector: #selector(CoreDataStack.persistentStoreDidImportUbiquitousContentChanges(_:)), name: NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges, object: nil)
    }
    
    func storesWillChange(_ notification: Notification) {
        managedObjectContext.perform {
            if self.managedObjectContext.hasChanges {
                do {
                    try self.managedObjectContext.save()
                } catch let err as NSError {
                    DDLogError("Error while saving context from 'storesWillChange:': \(err)")
                }
            }
            self.managedObjectContext.reset()
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: kCoreDataStackStoreWillChange), object: nil, userInfo: nil)
    }
    
    func storesDidChange(_ notification: Notification) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: kCoreDataStackStoreDidChange), object: nil, userInfo: nil)
    }
    
    func persistentStoreDidImportUbiquitousContentChanges(_ notification: Notification) {
        managedObjectContext.perform {
            self.managedObjectContext.mergeChanges(fromContextDidSave: notification)
            DDLogInfo("NSPersistentStoreDidImportUbiquitousContentChangesNotification executed")
        }
    }
    
}
