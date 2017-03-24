//
//  Complication.swift
//  Dependn
//
//  Created by David Miotti on 14/06/16.
//  Copyright © 2016 David Miotti. All rights reserved.
//

import ClockKit

private let todayString = NSLocalizedString("addiction.count_short", comment: "")

final class ComplicationController: NSObject, CLKComplicationDataSource {

    override init() {
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ComplicationController.contextDidUpdate(_:)),
            name: Notification.Name.WatchExtensionContextUpdatedNotificationName,
            object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var stats: WatchStatsAddiction? {
        return WatchSessionManager.sharedManager.context.stats
    }

    func requestedUpdateDidBegin() {
        WatchSessionManager.sharedManager.requestContext()
    }

    func requestedUpdateBudgetExhausted() {
        WatchSessionManager.sharedManager.requestContext()
    }

    fileprivate func reloadComplications() {
        if let actives = CLKComplicationServer.sharedInstance().activeComplications {
            actives.forEach { c in
                CLKComplicationServer.sharedInstance().reloadTimeline(for: c)
            }
        }
    }

    fileprivate func isMostRecentSinceLast(_ otherSinceLast: Date) -> Bool {
        guard let stats = stats else {
            return false
        }
        return stats.sinceLast.compare(otherSinceLast as Date) != .orderedSame
    }
    
    func getNextRequestedUpdateDate(handler: @escaping (Date?) -> Void) {
        let next = Date(timeIntervalSinceNow: 60 * 60)
        handler(next)
    }
    
    func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {

        let fullLast = String(format: NSLocalizedString("watch.sinceLast", comment: ""), stringFromTimeInterval(1620))

        let in27min = Date().addingTimeInterval(1620)

        var template: CLKComplicationTemplate? = nil

        switch complication.family {

        case .modularSmall:
            let t = CLKComplicationTemplateModularSmallSimpleText()
            t.textProvider = CLKRelativeDateTextProvider(date: in27min, style: .natural, units: [.day, .hour, .minute, .second])
            template = t

        case .modularLarge:
            let t = CLKComplicationTemplateModularLargeTable()
            t.tintColor = .purple
            t.column2Alignment = .trailing
            t.headerTextProvider = CLKSimpleTextProvider(text: NSLocalizedString("addiction.fakename", comment: ""))
            t.row1Column1TextProvider = CLKSimpleTextProvider(text: NSLocalizedString("addiction.last", comment: ""))
            t.row2Column1TextProvider = CLKSimpleTextProvider(text: NSLocalizedString("addiction.count", comment: ""))
            t.row1Column2TextProvider = CLKRelativeDateTextProvider(date: in27min as Date, style: .natural, units: [.day, .hour, .minute, .second])
            t.row2Column2TextProvider = CLKSimpleTextProvider(text: "17")
            template = t

        case .utilitarianSmall:
            let t = CLKComplicationTemplateUtilitarianSmallFlat()
            t.textProvider = CLKSimpleTextProvider(text: "10 \(todayString), 27m", shortText: "10, 27m")
            template = t

        case .utilitarianLarge:
            let t = CLKComplicationTemplateUtilitarianLargeFlat()
            t.textProvider = CLKSimpleTextProvider(
                text: "Cig. 10 \(todayString), \(fullLast)",
                shortText: "10, 27m")
            template = t

        case .circularSmall:
            let t = CLKComplicationTemplateCircularSmallSimpleText()
            t.textProvider = CLKRelativeDateTextProvider(date: in27min as Date, style: .natural, units: [.day, .hour, .minute, .second])
            t.tintColor = .white
            template = t
            
        default:
            break
        }

        handler(template)
    }

    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }

    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        if let stats = stats {
            let template = self.buildComplication(complication, withStats: stats)
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timelineEntry)
        } else {
            handler(nil)
        }
    }

    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        if let stats = stats, stats.sinceLast.compare(date as Date) == .orderedAscending {
            let template = self.buildComplication(complication, withStats: stats)
            let timelineEntry = CLKComplicationTimelineEntry(date: stats.sinceLast, complicationTemplate: template)
            handler([timelineEntry])
        } else {
            handler(nil)
        }
    }

    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        if let stats = stats, stats.sinceLast.compare(date as Date) == .orderedDescending {
            let template = self.buildComplication(complication, withStats: stats)
            let timelineEntry = CLKComplicationTimelineEntry(date: stats.sinceLast, complicationTemplate: template)
            handler([timelineEntry])
        } else {
            handler(nil)
        }
    }

    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([CLKComplicationTimeTravelDirections.backward, CLKComplicationTimeTravelDirections.forward])
    }

    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(stats?.sinceLast)
    }

    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Date())
    }

    fileprivate func buildComplication(_ complication: CLKComplication, withStats stats: WatchStatsAddiction, date: Date = Date()) -> CLKComplicationTemplate {

        let addictionName = stats.addiction
        let index = addictionName.index(addictionName.startIndex, offsetBy: 3)
        let obfuscated = addictionName.substring(to: index)

        let count: String
        if let first = stats.values.first {
            count = "\(first.value)"
        } else {
            count = "0"
        }

        let interval = date.timeIntervalSince(stats.sinceLast)
        let shortSinceLast = stringFromTimeInterval(interval)
        let fullSinceLast = stats.formattedSinceLast

        switch complication.family {
        case .modularSmall:
            let tmpl = CLKComplicationTemplateModularSmallSimpleText()
            tmpl.textProvider = CLKRelativeDateTextProvider(date: stats.sinceLast, style: .natural, units: [.day, .hour, .minute, .second])
            return tmpl

        case .modularLarge:
            let tmpl = CLKComplicationTemplateModularLargeTable()
            tmpl.tintColor = .purple
            tmpl.column2Alignment = .trailing
            tmpl.headerTextProvider = CLKSimpleTextProvider(text: stats.addiction)
            tmpl.row1Column1TextProvider = CLKSimpleTextProvider(text: NSLocalizedString("addiction.last", comment: ""), shortText: NSLocalizedString("addiction.last_short", comment: ""))
            tmpl.row2Column1TextProvider = CLKSimpleTextProvider(text: NSLocalizedString("addiction.count", comment: ""), shortText: todayString)
            tmpl.row1Column2TextProvider = CLKRelativeDateTextProvider(date: stats.sinceLast, style: .natural, units: [.day, .hour, .minute, .second])
            tmpl.row2Column2TextProvider = CLKSimpleTextProvider(text: count)
            return tmpl

        case .utilitarianSmall, .utilitarianSmallFlat:
            let tmpl = CLKComplicationTemplateUtilitarianSmallFlat()
            tmpl.textProvider = CLKSimpleTextProvider(text: "\(count), \(shortSinceLast)", shortText: "\(shortSinceLast)")
            return tmpl

        case .utilitarianLarge:
            let flatLarge = CLKComplicationTemplateUtilitarianLargeFlat()
            let text = "\(obfuscated). \(count) \(todayString), \(fullSinceLast)"
            flatLarge.textProvider = CLKSimpleTextProvider(text: text, shortText: "\(count), \(fullSinceLast)")
            return flatLarge

        case .circularSmall:
            let tmpl = CLKComplicationTemplateCircularSmallSimpleText()
            tmpl.textProvider = CLKRelativeDateTextProvider(date: stats.sinceLast, style: .natural, units: [.day, .hour, .minute, .second])
            tmpl.tintColor = .white
            return tmpl
            
        case .extraLarge:
            if #available(watchOSApplicationExtension 3.0, *) {
                let tmpl = CLKComplicationTemplateExtraLargeSimpleText()
                tmpl.textProvider = CLKRelativeDateTextProvider(date: stats.sinceLast, style: .natural, units: [.day, .hour, .minute, .second])
                return tmpl
            }
            let tmpl = CLKComplicationTemplateModularSmallSimpleText()
            tmpl.textProvider = CLKRelativeDateTextProvider(date: stats.sinceLast, style: .natural, units: [.day, .hour, .minute, .second])
            return tmpl
        }
    }

    fileprivate var cachedStats: WatchStatsAddiction?
    func contextDidUpdate(_ notification: Notification) {
        if let context = notification.userInfo?["context"] as? AppContext, let contextStats = context.stats {
            if let cached = cachedStats {
                if contextStats.sinceLast.compare(cached.sinceLast) != .orderedSame {
                    cachedStats = context.stats
                    reloadComplications()
                }
            } else {
                cachedStats = context.stats
                reloadComplications()
            }
        }
    }
}
