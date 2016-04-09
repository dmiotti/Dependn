//
//  XLSExportOperation.swift
//  Dependn
//
//  Created by David Miotti on 07/04/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import UIKit
import SwiftHelpers
import CoreData
import xlsxwriter

private let kExportOperationDayFormatter = NSDateFormatter(dateFormat: "dd/MM/yyyy")
private let kExportOperationHourFormatter = NSDateFormatter(dateFormat: "HH:mm")

final class XLSExportOperation: SHOperation {
    
    let path: String
    var error: NSError?
    
    let context: NSManagedObjectContext
    
    init(path: String) {
        self.path = path
        context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = CoreDataStack.shared.managedObjectContext
    }
    
    override func execute() {
        
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            } catch let err as NSError {
                print("Error while deleting file \(path): \(err)")
                error = err
                return
            }
            
        }
        
        context.performBlockAndWait {
            
            let headers = [
                L("export.date"),
                L("export.time"),
                L("export.intensity"),
                L("export.place"),
                L("export.feeling"),
                L("export.comment"),
                L("export.desire"),
                L("export.conso")
            ]
            
            do {
                let addictions = try Addiction.getAllAddictionsOrderedByCount(inContext: self.context)

                let workbook = new_workbook(self.path)
                
                let bold = workbook_add_format(workbook)
                format_set_bold(bold)
                
                for addiction in addictions {
                    
                    // Build xlsx header
                    let name = addiction.name.firstLetterCapitalization
                    let worksheet = workbook_add_worksheet(workbook, name)
                    worksheet_set_column(worksheet, 0, UInt16(headers.count), 15, nil)
                    
                    // Add the addiction name
                    worksheet_write_string(worksheet, 0, 0, name, bold)
                    
                    var rowIdx = 2
                    
                    for (colIdx ,header) in headers.enumerate() {
                        worksheet_write_string(
                            worksheet,
                            UInt32(rowIdx), UInt16(colIdx),
                            header, bold)
                    }
                    
                    rowIdx += 1
                    
                    let req = NSFetchRequest(entityName: Record.entityName)
                    req.predicate = NSPredicate(format: "addiction == %@", addiction)
                    req.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: false) ]
                    let records = try self.context.executeFetchRequest(req) as! [Record]
                    
                    for (recIdx, record) in records.enumerate() {
                        let values = self.recordToValues(record)
                        for (colIdx, value) in values.enumerate() {
                            worksheet_write_string(worksheet,
                                UInt32(rowIdx + recIdx), UInt16(colIdx), value, nil)
                        }
                    }
                }
                
                workbook_close(workbook)
                
                
            } catch let err as NSError {
                print("Error exporting xlsx: \(err)")
                self.error = err
            }
            
        }
        
        finish()
    }
    
    private func recordToValues(record: Record) -> [String] {
        let date = record.date
        return [
            kExportOperationDayFormatter.stringFromDate(date),
            kExportOperationHourFormatter.stringFromDate(date),
            String(format: "%.1f", arguments: [ record.intensity.floatValue ]),
            record.place?.name.firstLetterCapitalization ?? "",
            record.feeling ?? "",
            record.comment ?? "",
            record.desire.boolValue ? L("export.choosen") : "",
            record.desire.boolValue ? "" : L("export.choosen")
        ]
    }

}
