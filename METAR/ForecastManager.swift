//
//  ForecastManager.swift
//  METAR
//
//  Created by Kate Zyryanova on 25/01/16.
//  Copyright © 2016 home. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa

class ForecastManager : NSObject, UISearchBarDelegate {
    
    private var newMetarForecast = Signal<METAR, NSError>.pipe()
    var newMetarForecastSignal : Signal<METAR, NSError> {
        return newMetarForecast.0
    }
    
    private var errorFetchingData = Signal<NSError?, NoError>.pipe()
    var errorFetchingDataSignal : Signal<NSError?, NoError> {
        return errorFetchingData.0
    }
    
    private var waitingForResponse = Signal<AnyObject?, NoError>.pipe()
    var waitingForResponseSignal : Signal<AnyObject?, NoError> {
        return waitingForResponse.0
    }
    
    deinit {
        errorFetchingData.1.sendCompleted()
        newMetarForecast.1.sendCompleted()
    }
    
    // MARK - UISearchBarDelegate
    
    private var lastSearchText : String?
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if let lastSearchText = lastSearchText where searchText == lastSearchText {
            return
        } else if searchText.characters.count == 4 {
            lastSearchText = searchText
            waitingForResponse.1.sendNext(nil)
            APIManager.fetchMETAR(searchText).observe { [weak self] event in
                switch event {
                case let .Next(value):
                    self?.extractValue(value)
                case let .Failed(error):
                    self?.errorFetchingData.1.sendNext(error)
                case .Interrupted:
                    self?.errorFetchingData.1.sendNext(NSError(domain: "com.home", code: 666, userInfo: [
                        NSLocalizedDescriptionKey : "ICAO code incorrect"]))
                default:
                    break
                }
            }
        }
        
    }
    
    func extractValue(value : Dictionary<String, AnyObject>?) {
        if let value = value {
            let metar : METAR?
            do {
                metar = try METAR(dictionary: value)
            } catch METARInitializationError.InvalidDataFormat {
                self.errorFetchingData.1.sendNext(NSError(domain: "com.home", code: 666, userInfo: [
                    NSLocalizedDescriptionKey : "Invalid data format"]))
                metar = nil
            } catch METARInitializationError.METARNotFound {
                self.errorFetchingData.1.sendNext(NSError(domain: "com.home", code: 666, userInfo: [
                    NSLocalizedDescriptionKey : "METAR not found"]))
                metar = nil
            } catch {
                metar = nil
                self.errorFetchingData.1.sendNext(NSError(domain: "com.home", code: 666, userInfo: [
                    NSLocalizedDescriptionKey : "Something totally wrong"]))
            }
            if let metar = metar {
                self.newMetarForecast.1.sendNext(metar)
            }
        }
    }
    
}