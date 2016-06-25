//
//  ExportOperation.swift
//  Dependn
//
//  Created by David Miotti on 23/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import SwiftHelpers
import CoreData
import CoreLocation
import BrightFutures
import CocoaLumberjack

private let kExportOperationSeparator = ";"
private let kExportOperationNewLine = "\n"
private let kExportOperationDayFormatter = NSDateFormatter(dateFormat: "dd/MM/yyyy")
private let kExportOperationHourFormatter = NSDateFormatter(dateFormat: "HH:mm")

final class CSVExportOperation: SHOperation {
    
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
                    L("export.lon"),
                    L("export.desire"),
                    L("export.conso")
                ].joinWithSeparator(kExportOperationSeparator)

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
            record.lon?.stringValue ?? "",
            record.desire.boolValue ? L("export.choosen") : "",
            record.desire.boolValue ? "" : L("export.choosen")
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
