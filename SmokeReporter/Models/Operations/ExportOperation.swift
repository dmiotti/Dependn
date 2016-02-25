//
//  ExportOperation.swift
//  SmokeReporter
//
//  Created by David Miotti on 23/02/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData

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
            smoke.type,
            String(format: "%.1f", arguments: [ smoke.intensity.floatValue ]),
            smoke.before ?? "",
            smoke.after ?? "",
            smoke.comment ?? "",
            smoke.place?.name ?? "",
            smoke.place?.lat.stringValue ?? "",
            smoke.place?.lon.stringValue ?? ""
        ]
        return values.joinWithSeparator(kExportOperationSeparator)
    }
    
    private func exportPath() -> String {
        let fileUUID = NSUUID().UUIDString
        return applicationCachesDirectory
            .URLByAppendingPathComponent(fileUUID)
            .URLByAppendingPathExtension("csv").path!
    }
    
    private lazy var applicationCachesDirectory: NSURL = {
        let urls = NSFileManager.defaultManager()
            .URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

}

final class ImportOperation: SHOperation {
    
    var error: NSError?
    
    private let path: String
    private let context: NSManagedObjectContext
    
    init(path: String) {
        self.path = path
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
        super.init()
    }
    
    override func execute() {
        do {
            let csv = try String(contentsOfFile: path, encoding: NSUTF8StringEncoding)
            
            context.performBlockAndWait {
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
            
            try saveContext()
        } catch let err as NSError {
            self.error = err
        }
        
        finish()
    }
    
    private func saveContext() throws {
        var ctx: NSManagedObjectContext? = context
        while let c = ctx {
            try c.save()
            ctx = c.parentContext
        }
    }
    
    private func newRecordFromValues(values: [String]) {
        if values.count < 7 {
            return
        }
        
        let daystr = values[0]
        let hourstr = values[1]
        let datestr = "\(daystr) \(hourstr)"
        let date = kImportOperationDateFormatter.dateFromString(datestr) ?? NSDate()
        let type = values[2] == "Joint" ? SmokeType.Weed : SmokeType.Cigarette
        let intensity = NSString(string: values[3]).floatValue
        let before = values[4]
        let after = values[5]
        let comment = values[6]
        
        var place: Place? = nil
        if values.count == 10 {
            let lat = values[8]
            let lon = values[9]
            if lat.characters.count > 0 && lon.characters.count > 0 {
                let name = values[7]
                let placeName: String? = name.characters.count > 0 ? name : nil
                place = Place.insertNewPlace(placeName, lat: lat, lon: lon)
            }
        }
        
        Smoke.insertNewSmoke(type,
            intensity: intensity,
            before: before,
            after: after,
            comment: comment,
            place: place,
            date: date,
            inContext: context)
    }
    
}
