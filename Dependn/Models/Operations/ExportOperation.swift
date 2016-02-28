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
                let req = NSFetchRequest(entityName: Smoke.entityName)
                req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: true) ]
                let smokes = try self.context.executeFetchRequest(req) as! [Smoke]
                
                let path = self.exportPath()
                let csv = self.createCSV(smokes)
                
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
    
    private func createCSV(smokes: [Smoke]) -> String {
        let header = [
            L("export.date"),
            L("export.time"),
            L("export.type"),
            L("export.intensity"),
            L("export.before"),
            L("export.after"),
            L("export.comment"),
            L("export.place"),
            L("export.lat"),
            L("export.lon") ]
            .joinWithSeparator(kExportOperationSeparator)
        
        let content = smokes.map({ recordToCSV($0) })
            .joinWithSeparator(kExportOperationNewLine)
        return header + kExportOperationNewLine
            + content + kExportOperationNewLine
    }
    
    private func recordToCSV(smoke: Smoke) -> String {
        let date = smoke.date
        let values = [
            kExportOperationDayFormatter.stringFromDate(date),
            kExportOperationHourFormatter.stringFromDate(date),
            smoke.smokeType == .Cig ? L("export.cig") : L("export.weed"),
            String(format: "%.1f", arguments: [ smoke.intensity.floatValue ]),
            smoke.before ?? "",
            smoke.after ?? "",
            smoke.comment ?? "",
            smoke.place ?? "",
            smoke.lat?.stringValue ?? "",
            smoke.lon?.stringValue ?? ""
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

public let kImportOperationErrorDomain = "ImportOperation"
public let kImportOperationNothingToImportCode = 1
public let kImportOperationUserCancelledCode = 2

final class ImportOperation: SHOperation {
    
    private(set) var error: NSError?
    
    private let context: NSManagedObjectContext
    private let controller: UIViewController
    
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
                            try self.deleteAllSmokes()
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
            self.newRecordFromValues(values)
        }
    }
    
    private func deleteAllSmokes() throws {
        let req = NSFetchRequest(entityName: Smoke.entityName)
        req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: true) ]
        let smokes = try self.context.executeFetchRequest(req) as! [Smoke]
        for smoke in smokes {
            self.context.deleteObject(smoke)
        }
    }
    
    private func saveContext() throws {
        var ctx: NSManagedObjectContext? = context
        while let c = ctx {
            try c.save()
            ctx = c.parentContext
        }
    }
    
    private func newRecordFromValues(values: [String]) {
        if values.count < 10 {
            return
        }
        let daystr = values[0]
        let hourstr = values[1]
        let datestr = "\(daystr) \(hourstr)"
        let date = kImportOperationDateFormatter.dateFromString(datestr) ?? NSDate()
        let type: SmokeType = values[2] == "Weed" ? .Weed : .Cig
        let intensity = NSString(string: values[3]).floatValue
        let before = values[4]
        let after = values[5]
        let comment = values[6]
        let place = values[7]
        let lat = values[8]
        let lon = values[9]
        
        Smoke.insertNewSmoke(type,
            intensity: intensity,
            before: before,
            after: after,
            comment: comment,
            place: place,
            latitude: doubleOrNil(lat),
            longitude: doubleOrNil(lon),
            date: date,
            inContext: context)
    }
    
    private func doubleOrNil(value: String) -> Double? {
        if value.characters.count > 0 {
            return Double(value.floatValue)
        }
        return nil
    }
    
}
