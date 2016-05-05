//
//  NetworkManager.swift
//  METAR
//
//  Created by Kate Zyryanova on 25/01/16.
//  Copyright © 2016 home. All rights reserved.
//

import Foundation
import ReactiveCocoa

class APIManager {
    
    class func fetchMETAR(code : String) -> Signal<Dictionary<String, AnyObject>?, NSError> {
        guard let URL = NSURL(string: "http://avwx.rest/api/metar.php?station=\(code)&format=JSON&options=info,translate") else {
            return Signal {
                sink in
                sink.sendInterrupted()
                return SimpleDisposable()
            }
        }
        let request = NSMutableURLRequest(URL: URL)
        return get(request).map({ (value) -> Dictionary<String, AnyObject>? in
            return value as? Dictionary<String, AnyObject>
        })
    }
    
    private class func post(request: NSMutableURLRequest) -> Signal<AnyObject, NSError> {
        return dataTask(request, method: "POST")
    }
    
    private class func put(request: NSMutableURLRequest) -> Signal<AnyObject, NSError> {
        return dataTask(request, method: "PUT")
    }
    
    private class func get(request: NSMutableURLRequest) -> Signal<AnyObject, NSError> {
        return dataTask(request, method: "GET")
    }
    
    private class func dataTask(request: NSMutableURLRequest, method: String) -> Signal<AnyObject, NSError> {
        return Signal<AnyObject, NSError> {
            sink in
            request.HTTPMethod = method
            let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
            let dataTask = session.dataTaskWithRequest(request) {
                (data, response, error) -> Void in
                if let data = data {
                    let json = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                    if let response = response as? NSHTTPURLResponse where 200...299 ~= response.statusCode, let json = json {
                        sink.sendNext(json)
                        sink.sendCompleted()
                    } else {
                        let error = error ?? NSError(domain: "com.home", code: 666, userInfo: [
                            NSLocalizedDescriptionKey : "Unknown error"])
                        sink.sendFailed(error)
                    }
                }
            }
            dataTask.resume()
            return ActionDisposable {
                dataTask.cancel()
                sink.sendInterrupted()
            }
        }
    }
    
    
}