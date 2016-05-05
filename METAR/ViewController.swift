//
//  ViewController.swift
//  METAR
//
//  Created by Kate Zyryanova on 25/01/16.
//  Copyright © 2016 home. All rights reserved.
//

import UIKit
import ReactiveCocoa

class ViewController: UIViewController {
    
    var forecastManager = ForecastManager()
    
    @IBOutlet weak var searchBar : UISearchBar?
    @IBOutlet weak var textLabel : UILabel?
    @IBOutlet weak var activityIndicator : UIActivityIndicatorView?
    
    let dateFormatter : NSDateFormatter =  {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "HH:mm, dd MMM"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar?.delegate = forecastManager
        forecastManager.newMetarForecastSignal.observeOn(UIScheduler()).observeNext { [weak self] someObject in
            self?.activityIndicator?.stopAnimating()
            self?.textLabel?.attributedText = self?.processTextForMETAR(someObject)
        }
        forecastManager.errorFetchingDataSignal.observeOn(UIScheduler()).observeNext { [weak self] anError in
            self?.activityIndicator?.stopAnimating()
            if let error = anError {
                self?.textLabel?.text = error.localizedDescription
            }
        }
        forecastManager.waitingForResponseSignal.observeOn(UIScheduler()).observeNext { [weak self] _ in
            self?.activityIndicator?.startAnimating()
        }
    }
    
    private func processTextForMETAR(metar: METAR) -> NSAttributedString {
        let str = NSMutableAttributedString()
        
        
        if let time = metar.forecastTime {
            addValue(dateFormatter.stringFromDate(time), withTitle: "Forecast time", toString: str)
        }
        
        // Set info values
        addValue(metar.info?.name, withTitle: "Airport", toString: str)
        addValue(metar.info?.IATACode, withTitle: "IATA", toString: str)
        addValue(metar.info?.ICAOCode, withTitle: "ICAO", toString: str)
        addValue(metar.info?.country, withTitle: "Country", toString: str)
        addValue(metar.info?.city, withTitle: "City", toString: str)
        if let elevation = metar.info?.elevation {
            addValue(String(elevation), withTitle: "Elevation", toString: str)
        }
        // Set raw metar value
        str.appendAttributedString(NSAttributedString(string: "\n" + metar.rawValue + "\n\n", attributes: textAttributes()))
        
        // Set translation values
        addValue(metar.translations?.temperature, withTitle: "Temperature", toString: str)
        addValue(metar.translations?.visibility, withTitle: "Visiblity", toString: str)
        addValue(metar.translations?.wind, withTitle: "Wind", toString: str)
        addValue(metar.translations?.altimeter, withTitle: "Altimeter", toString: str)
        addValue(metar.translations?.clouds, withTitle: "Clouds", toString: str)
        addValue(metar.translations?.dewpoint, withTitle: "Dewpoint", toString: str)
        addValue(metar.translations?.other, withTitle: "Other", toString: str)
        
        return str
    }
    
    private func addValue(value: String?, withTitle title: String, toString mutableString: NSMutableAttributedString) {
        if let value = value where value.characters.count > 0 {
            mutableString.appendAttributedString(NSAttributedString(string: "\(title): ", attributes: titleAttributes()))
            mutableString.appendAttributedString(NSAttributedString(string: "\(value)\n", attributes: textAttributes()))
        }
    }
    
    private func titleAttributes() -> [String : AnyObject] {
        return [
            NSForegroundColorAttributeName : UIColor.blackColor(),
            NSFontAttributeName : UIFont.boldSystemFontOfSize(17),
        ]
    }
    
    private func textAttributes() -> [String : AnyObject] {
        return [
            NSForegroundColorAttributeName : UIColor.blackColor(),
            NSFontAttributeName : UIFont.systemFontOfSize(15)
        ]
    }


}

