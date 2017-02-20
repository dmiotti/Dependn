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
            name: NSNotification.Name(rawValue: kWatchExtensionContextUpdatedNotificationName),
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

    private func reloadComplications() {
        if let actives = CLKComplicationServer.sharedInstance().activeComplications {
            actives.forEach { c in
                CLKComplicationServer.sharedInstance().reloadTimeline(for: c)
            }
        }
    }

    private func isMostRecentSinceLast(otherSinceLast: NSDate) -> Bool {
        guard let stats = stats else {
            return false
        }
        return stats.sinceLast.compare(otherSinceLast as Date) != .orderedSame
    }

    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        let next = NSDate(timeIntervalSinceNow: 60 * 60)
        handler(next)
    }

    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {

        let fullLast = String(format: NSLocalizedString("watch.sinceLast", comment: ""), stringFromTimeInterval(interval: 1620))

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
        }

        handler(template)
    }

    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }

    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimelineEntry?) -> Void) {
        if let stats = stats {
            let template = self.buildComplication(complication: complication, withStats: stats)
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timelineEntry)
        } else {
            handler(nil)
        }
    }

    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: ([CLKComplicationTimelineEntry]?) -> Void) {
        if let stats = stats, stats.sinceLast.compare(date as Date) == .orderedAscending {
            let template = self.buildComplication(complication: complication, withStats: stats)
            let timelineEntry = CLKComplicationTimelineEntry(date: stats.sinceLast, complicationTemplate: template)
            handler([timelineEntry])
        } else {
            handler(nil)
        }
    }

    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: ([CLKComplicationTimelineEntry]?) -> Void) {
        if let stats = stats, stats.sinceLast.compare(date as Date) == .orderedDescending {
            let template = self.buildComplication(complication: complication, withStats: stats)
            let timelineEntry = CLKComplicationTimelineEntry(date: stats.sinceLast, complicationTemplate: template)
            handler([timelineEntry])
        } else {
            handler(nil)
        }
    }

    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([CLKComplicationTimeTravelDirections.backward, CLKComplicationTimeTravelDirections.forward])
    }

    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(stats?.sinceLast as NSDate)
    }

    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(NSDate())
    }

    private func buildComplication(complication: CLKComplication, withStats stats: WatchStatsAddiction, date: NSDate = NSDate()) -> CLKComplicationTemplate {

        let obfuscated = stats.addiction.substringToIndex(stats.addiction.startIndex.advancedBy(3))

        let count: String
        if let first = stats.values.first {
            count = "\(first.value)"
        } else {
            count = "0"
        }

        let interval = date.timeIntervalSince(stats.sinceLast)
        let shortSinceLast = stringFromTimeInterval(interval: interval)
        let fullSinceLast = stats.formattedSinceLast

        let template: CLKComplicationTemplate

        switch complication.family {

        case .modularSmall:
            let t = CLKComplicationTemplateModularSmallSimpleText()
            t.textProvider = CLKRelativeDateTextProvider(date: stats.sinceLast, style: .natural, units: [.day, .hour, .minute, .second])
            template = t

        case .modularLarge:
            let t = CLKComplicationTemplateModularLargeTable()
            t.tintColor = .purple
            t.column2Alignment = .trailing
            t.headerTextProvider = CLKSimpleTextProvider(text: stats.addiction)
            t.row1Column1TextProvider = CLKSimpleTextProvider(text: NSLocalizedString("addiction.last", comment: ""), shortText: NSLocalizedString("addiction.last_short", comment: ""))
            t.row2Column1TextProvider = CLKSimpleTextProvider(text: NSLocalizedString("addiction.count", comment: ""), shortText: todayString)
            t.row1Column2TextProvider = CLKRelativeDateTextProvider(date: stats.sinceLast, style: .natural, units: [.day, .hour, .minute, .second])
            t.row2Column2TextProvider = CLKSimpleTextProvider(text: count)
            template = t

        case .utilitarianSmall:
            let t = CLKComplicationTemplateUtilitarianSmallFlat()
            t.textProvider = CLKSimpleTextProvider(text: "\(count), \(shortSinceLast)", shortText: "\(shortSinceLast)")
            template = t

        case .utilitarianLarge:
            let t = CLKComplicationTemplateUtilitarianLargeFlat()
            let text = "\(obfuscated). \(count) \(todayString), \(fullSinceLast)"
            t.textProvider = CLKSimpleTextProvider(text: text, shortText: "\(count), \(fullSinceLast)")
            template = t

        case .circularSmall:
            let t = CLKComplicationTemplateCircularSmallSimpleText()
            t.textProvider = CLKRelativeDateTextProvider(date: stats.sinceLast, style: .natural, units: [.day, .hour, .minute, .second])
            t.tintColor = .white
            template = t
        }

        return template
    }

    private var cachedStats: WatchStatsAddiction?
    func contextDidUpdate(_ notification: NSNotification) {
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
