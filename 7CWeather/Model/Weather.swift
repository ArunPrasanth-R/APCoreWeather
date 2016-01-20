//
//  Weather.swift
//  7CWeather
//
//  Created by ArunPrasanth R on 19/01/16.
//  Copyright © 2016 ArunPrasanth R. All rights reserved.
//

import UIKit

class Weather: NSObject {
    
    var tempC:String?
    var tempF:String?
    var date:String?
    var weatherIcon:NSData?
    
    func parseWeatherData(obj:AnyObject?) {
        
        
        tempC = obj! .objectForKey("tempMaxC") as? String
        tempF = obj! .objectForKey("tempMaxF") as? String
        date = obj! .objectForKey("date") as? String
        
        let url = NSURL(string: (obj! .objectForKey("weatherIconUrl")![0] .objectForKey("value") as? String)!)
        if let data = NSData(contentsOfURL: url!){
            weatherIcon = data
        }
    }
}
