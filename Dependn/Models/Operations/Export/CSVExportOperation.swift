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
private let kExportOperationDayFormatter = DateFormatter(dateFormat: "dd/MM/yyyy")
private let kExportOperationHourFormatter = DateFormatter(dateFormat: "HH:mm")

final class CSVExportOperation: SHOperation {
    
    var exportedPath: String?
    var error: NSError?
    
    fileprivate let context: NSManagedObjectContext
    
    override init() {
        context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = CoreDataStack.shared.managedObjectContext
        super.init()
    }
    
    override func execute() {
        
        context.performAndWait {
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
                ].joined(separator: kExportOperationSeparator)

                csv.append(kExportOperationNewLine)
                
                for addiction in addictions {
                    let req = NSFetchRequest<NSFetchRequestResult>(entityName: Record.entityName)
                    req.predicate = NSPredicate(format: "addiction == %@", addiction)
                    req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
                    let records = try self.context.fetch(req) as! [Record]
                    let recordsCsv = records.map({ self.recordToCSV($0) })
                        .joined(separator: kExportOperationNewLine)
                    csv.append(recordsCsv)
                    csv.append(kExportOperationNewLine)
                    csv.append(kExportOperationNewLine)
                }
                
                try csv.write(toFile: path,
                    atomically: true,
                    encoding: String.Encoding.utf8)
                
                self.exportedPath = path
            } catch let err as NSError {
                self.error = err
            }
        }
        
        finish()
    }
    
    fileprivate func recordToCSV(_ record: Record) -> String {
        let date = record.date
        let values = [
            record.addiction.name.firstLetterCapitalization,
            kExportOperationDayFormatter.string(from: date as Date),
            kExportOperationHourFormatter.string(from: date as Date),
            String(format: "%.1f", arguments: [ record.intensity.floatValue ]),
            record.place?.name.firstLetterCapitalization ?? "",
            record.feeling ?? "",
            record.comment ?? "",
            record.lat?.stringValue ?? "",
            record.lon?.stringValue ?? "",
            record.desire.boolValue ? L("export.choosen") : "",
            record.desire.boolValue ? "" : L("export.choosen")
        ]
        return values.joined(separator: kExportOperationSeparator)
    }
    
    fileprivate func exportPath() -> String {
        let dateFormatter = DateFormatter(dateFormat: "dd'_'MM'_'yyyy'_'HH'_'mm")
        let filename = "export_\(dateFormatter.string(from: Date()))"
        return applicationCachesDirectory.appendingPathComponent(filename).appendingPathComponent("csv").path
    }
    
    fileprivate lazy var applicationCachesDirectory: URL = {
        let urls = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
}
