//
//  CSVImportOperation.swift
//  Dependn
//
//  Created by David Miotti on 08/05/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import SwiftHelpers
import CoreData
import CoreLocation
import BrightFutures
import PKHUD
import CocoaLumberjack

let kImportOperationErrorDomain = "ImportOperation"
let kImportOperationNothingToImportCode = 1
let kImportOperationUserCancelledCode = 2

private let kImportOperationDateFormatter = NSDateFormatter(dateFormat: "dd/MM/yyyy HH:mm")

final class CSVImportOperation: SHOperation {
    
    private(set) var error: NSError?
    
    private let context: NSManagedObjectContext
    private let controller: UIViewController
    
    private var cachedPlaces = [Place]()
    
    init(controller: UIViewController) {
        self.controller = controller
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
        super.init()
    }
    
    override func execute() {
        let candidates = getCandidateFiles()
        if candidates.count > 0 {
            askForFile(candidates).onComplete { r in
                if let file = r.value {
                    dispatch_async(dispatch_get_main_queue()) {
                        HUD.show(.Progress)
                    }
                    self.context.performBlockAndWait {
                        do {
                            try self.deleteAllRecords()
                            try self.deleteAllAddictions()
                            try self.deleteAllPlaces()
                            try self.importFileAtURL(file)
                            try self.context.cascadeSave()
                        } catch let err as NSError {
                            self.error = err
                        }
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        HUD.hide(animated: true, completion: { finished in
                            self.finish()
                        })
                    }
                } else {
                    self.error = r.error
                    self.finish()
                }
            }
        } else {
            self.error = NSError(
                domain: kImportOperationErrorDomain,
                code: kImportOperationNothingToImportCode,
                userInfo: [
                    NSLocalizedDescriptionKey: L("import.no_data"),
                    NSLocalizedRecoverySuggestionErrorKey: L("import.no_data_suggestion")])
            finish()
        }
    }
    
    private func getCandidateFiles() -> [NSURL] {
        var candidates = [NSURL]()
        
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        if let directoryURL = urls.last {
            
            /// List all possible import to the user
            let enumerator = fileManager.enumeratorAtURL(directoryURL,
                                                         includingPropertiesForKeys: nil, options: .SkipsHiddenFiles, errorHandler: nil)
            
            while let element = enumerator?.nextObject() as? NSURL {
                if element.pathExtension == "csv" {
                    candidates.append(element)
                }
            }
        }
        
        return candidates
    }
    
    private func askForFile(files: [NSURL]) -> Future<NSURL, NSError> {
        let promise = Promise<NSURL, NSError>()
        
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertController(title: L("import.choose_file"), message: L("import.choose_file_message"), preferredStyle: .ActionSheet)
            
            for file in files {
                let filename = file.URLByDeletingPathExtension?.lastPathComponent
                let action = UIAlertAction(title: filename, style: .Default) { action in
                    promise.success(file)
                }
                alert.addAction(action)
            }
            
            let cancelAction = UIAlertAction(title: L("cancel"), style: .Cancel) { action in
                let err = NSError(domain: kImportOperationErrorDomain,
                                  code: kImportOperationUserCancelledCode,
                                  userInfo: [NSLocalizedDescriptionKey: L("import.cancelled_by_user"),
                                    NSLocalizedRecoverySuggestionErrorKey: L("import.cancelled_by_user_recovery")])
                promise.failure(err)
            }
            alert.addAction(cancelAction)
            
            self.controller.presentViewController(alert, animated: true, completion: nil)
        }
        
        return promise.future
    }
    
    private func importFileAtURL(URL: NSURL) throws {
        let csv = try String(contentsOfURL: URL, encoding: NSUTF8StringEncoding)
        let lines = csv.componentsSeparatedByCharactersInSet(
            NSCharacterSet.newlineCharacterSet())
        for (index, line) in lines.enumerate() {
            if index == 0 {
                continue
            }
            let values = line.componentsSeparatedByString(";")
            newRecordFromValues(values)
        }
    }
    
    private func deleteAllRecords() throws {
        let req = Record.entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: true) ]
        let records = try context.executeFetchRequest(req) as! [Record]
        for r in records {
            context.deleteObject(r)
        }
    }
    
    private func deleteAllAddictions() throws {
        let req = NSFetchRequest(entityName: Addiction.entityName)
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: true) ]
        let addictions = try context.executeFetchRequest(req) as! [Addiction]
        for addiction in addictions {
            context.deleteObject(addiction)
        }
    }
    
    private func deleteAllPlaces() throws {
        let req = Place.entityFetchRequest()
        req.sortDescriptors = [ NSSortDescriptor(key: "name", ascending: false) ]
        let places = try context.executeFetchRequest(req) as! [Place]
        for place in places {
            context.deleteObject(place)
        }
    }
    
    private func getPlaceOrCreate(name: String) -> Place {
        do {
            let pred = NSPredicate(format: "name == %@", name)
            let places = try Place.allPlaces(inContext: context, usingPredicate: pred)
            if let first = places.first {
                return first
            }
        } catch let err as NSError {
            print("Error while getting all places: \(err)")
        }
        
        return Place.insertPlace(name, inContext: context)
    }
    
    private func newRecordFromValues(values: [String]) {
        if values.count < 9 {
            return
        }
        
        do {
            let addiction = try Addiction.findOrInsertNewAddiction(values[0],
                                                                   inContext: context)
            
            let daystr = values[1]
            let hourstr = values[2]
            let datestr = "\(daystr) \(hourstr)"
            let date = kImportOperationDateFormatter.dateFromString(datestr) ?? NSDate()
            let intensity = NSString(string: values[3]).floatValue
            let placeName = values[4]
            let feeling = values[5]
            let comment = values[6]
            let lat = values[7]
            let lon = values[8]
            let isDesire: Bool
            if values.count > 9 {
                let desire = values[9]
                isDesire = desire.characters.count > 0
            } else {
                isDesire = false
            }
            
            var place: Place? = nil
            if placeName.characters.count > 0 {
                place = getPlaceOrCreate(placeName)
            }
            
            Record.insertNewRecord(addiction,
                                   intensity: intensity,
                                   feeling: feeling,
                                   comment: comment,
                                   place: place,
                                   latitude: doubleOrNil(lat),
                                   longitude: doubleOrNil(lon),
                                   desire: isDesire,
                                   date: date,
                                   inContext: context)
        } catch let err as NSError {
            DDLogError("Error while adding new record: \(err)")
        }
    }
    
    private func doubleOrNil(value: String) -> Double? {
        if value.characters.count > 0 {
            return Double(value.floatValue)
        }
        return nil
    }
    
}
