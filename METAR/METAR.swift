//
//  METAR.swift
//  METAR
//
//  Created by Kate Zyryanova on 25/01/16.
//  Copyright © 2016 home. All rights reserved.
//

import Foundation

enum METARInitializationError : ErrorType {
    case InvalidDataFormat
    case METARNotFound
}

final class METAR {
    
    var rawValue : String
    var forecastTime : NSDate?
    
    var info : METARInfo?
    var translations : METARTranslations?
    
    
    init(dictionary: Dictionary<String, AnyObject>) throws {
        self.rawValue = ""
        if let _ = dictionary["Error"] as? String {
            throw METARInitializationError.METARNotFound
        }
        guard let rawValue = dictionary["Raw-Report"] as? String else {
            throw METARInitializationError.InvalidDataFormat
        }
        guard let metarTime = dictionary["Time"] as? String where metarTime.characters.count == 7 else {
            throw METARInitializationError.InvalidDataFormat
        }
        self.rawValue = rawValue
        
        let day = metarTime[metarTime.startIndex..<metarTime.startIndex.advancedBy(2)]
        let hours = metarTime[metarTime.startIndex.advancedBy(2)..<metarTime.startIndex.advancedBy(4)]
        let minutes = metarTime[metarTime.startIndex.advancedBy(4)..<metarTime.startIndex.advancedBy(6)]

        let calendar = NSCalendar.currentCalendar()
        let components = calendar.componentsInTimeZone(NSTimeZone(abbreviation: "UTC")!,
            fromDate: NSDate())
        if let dayValue = Int(day), hourValue = Int(hours), minuteValue = Int(minutes) {
            components.day = dayValue
            components.hour = hourValue
            components.minute = minuteValue
        }
        self.forecastTime = calendar.dateFromComponents(components)
        if let info = dictionary["Info"] as? Dictionary<String, AnyObject> {
            self.setInfoWithDictionary(info)
        }
        if let translations = dictionary["Translations"] as? Dictionary<String, AnyObject> {
            self.setTranslationsWithDictionary(translations)
        }
    }
    
    private func setInfoWithDictionary(dictionary: Dictionary<String, AnyObject>) {
        self.info = METARInfo()
        self.info?.city = dictionary["City"] as? String
        self.info?.country = dictionary["Country"] as? String
        self.info?.elevation = dictionary["Elevation"] as? Int
        self.info?.IATACode = dictionary["IATA"] as? String
        self.info?.ICAOCode = dictionary["ICAO"] as? String
        self.info?.name = dictionary["Name"] as? String
    }
    
    private func setTranslationsWithDictionary(dictionary: Dictionary<String, AnyObject>) {
        self.translations = METARTranslations()
        self.translations?.altimeter = dictionary["Altimeter"] as? String
        self.translations?.clouds = dictionary["Clouds"] as? String
        self.translations?.dewpoint = dictionary["Dewpoint"] as? String
        self.translations?.other = dictionary["Other"] as? String
        self.translations?.temperature = dictionary["Temperature"] as? String
        self.translations?.visibility = dictionary["Visibility"] as? String
        self.translations?.wind = dictionary["Wind"] as? String
    }
}