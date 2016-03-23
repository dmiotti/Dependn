//
//  ExportOperation.swift
//  Dependn
//
//  Created by David Miotti on 23/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData
import CoreLocation
import BrightFutures
import PKHUD
import CocoaLumberjack

private let kExportOperationSeparator = ";"
private let kExportOperationNewLine = "\n"
private let kExportOperationDayFormatter = NSDateFormatter(dateFormat: "dd/MM/yyyy")
private let kExportOperationHourFormatter = NSDateFormatter(dateFormat: "HH:mm")
private let kImportOperationDateFormatter = NSDateFormatter(dateFormat: "dd/MM/yyyy HH:mm")

final class ExportOperation: SHOperation {
    
    var exportedPath: String?
    var error: NSError?
    
    private let context: NSManagedObjectContext
    
    override init() {
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
        super.init()
    }
    
    override func execute() {
        
        context.performBlockAndWait {
            do {
                
                let addictions = try Addiction.getAllAddictionsOrderedByCount(inContext: self.context)
                
                let path = self.exportPath()

                var csv: String = [
                    L("export.type"),
                    L("export.date"),
                    L("export.time"),
                    L("export.intensity"),
                    L("export.place"),
                    L("export.feeling"),
                    L("export.comment"),
                    L("export.lat"),
                    L("export.lon") ].joinWithSeparator(kExportOperationSeparator)

                csv.appendContentsOf(kExportOperationNewLine)
                
                for addiction in addictions {
                    let req = NSFetchRequest(entityName: Record.entityName)
                    req.predicate = NSPredicate(format: "addiction == %@", addiction)
                    req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
                    let records = try self.context.executeFetchRequest(req) as! [Record]
                    let recordsCsv = records.map({ self.recordToCSV($0) })
                        .joinWithSeparator(kExportOperationNewLine)
                    csv.appendContentsOf(recordsCsv)
                    csv.appendContentsOf(kExportOperationNewLine)
                    csv.appendContentsOf(kExportOperationNewLine)
                }
                
                try csv.writeToFile(path,
                    atomically: true,
                    encoding: NSUTF8StringEncoding)
                
                self.exportedPath = path
            } catch let err as NSError {
                self.error = err
            }
        }
        
        finish()
    }
    
    private func recordToCSV(record: Record) -> String {
        let date = record.date
        let values = [
            record.addiction.name.firstLetterCapitalization,
            kExportOperationDayFormatter.stringFromDate(date),
            kExportOperationHourFormatter.stringFromDate(date),
            String(format: "%.1f", arguments: [ record.intensity.floatValue ]),
            record.place?.name.firstLetterCapitalization ?? "",
            record.feeling ?? "",
            record.comment ?? "",
            record.lat?.stringValue ?? "",
            record.lon?.stringValue ?? ""
        ]
        return values.joinWithSeparator(kExportOperationSeparator)
    }
    
    private func exportPath() -> String {
        let dateFormatter = NSDateFormatter(dateFormat: "dd'_'MM'_'yyyy'_'HH'_'mm")
        let filename = "export_\(dateFormatter.stringFromDate(NSDate()))"
        return applicationCachesDirectory
            .URLByAppendingPathComponent(filename)
            .URLByAppendingPathExtension("csv").path!
    }
    
    private lazy var applicationCachesDirectory: NSURL = {
        let urls = NSFileManager.defaultManager()
            .URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
}

let kImportOperationErrorDomain = "ImportOperation"
let kImportOperationNothingToImportCode = 1
let kImportOperationUserCancelledCode = 2

final class ImportOperation: SHOperation {
    
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
                            try self.saveContext()
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
    
    private func saveContext() throws {
        var ctx: NSManagedObjectContext? = context
        while let c = ctx {
            try c.save()
            ctx = c.parentContext
        }
    }
    
    private func getPlaceOrCreate(name: String) -> Place {
        let places = Place.allPlaces(inContext: context, usingPredicate: NSPredicate(format: "name == %@", name))
        if let first = places.first {
            return first
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
