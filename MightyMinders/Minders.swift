//
//  Minders.swift
//  MightyMinders
//
//  Created by Justin Bane on 9/10/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import Foundation
import MapKit

class Minders {
    
    let reminderSnapShot: FDataSnapshot
    let type: String
    
    var processedReminders: [Annotation] = []
    
    init(reminderSubData: FDataSnapshot, type: String) {
        self.reminderSnapShot = reminderSubData
        self.type = type
    }
    
    func processMinders() -> [Annotation] {
        
        let enumerator = reminderSnapShot.children
        while let data = enumerator.nextObject() as? FDataSnapshot {
            
            // add reminders to map
            let pinLocation = data.value.valueForKey("location") as! NSDictionary
            
            var timing = 0
            if let FBTiming = data.value.valueForKey("timing") as? Int {
                timing = FBTiming
            }
            
            var setFor = ""
            if data.value.valueForKey("set-for") !== nil {
                setFor = data.value.valueForKey("set-for") as! String
            }
            
            var setBy = ""
            if data.value.valueForKey("set-by") !== nil {
                setBy = data.value.valueForKey("set-by") as! String
            }
            
            let annotation = Annotation(
                key: data.key,
                title: pinLocation.valueForKey("name") as! String,
                subtitle: pinLocation.valueForKey("address") as! String,
                content: data.value.valueForKey("content") as! String,
                type: self.type,
                event: timing,
                coordinate: CLLocationCoordinate2D(
                    latitude: pinLocation.valueForKey("latitude") as! CLLocationDegrees,
                    longitude: pinLocation.valueForKey("longitude") as! CLLocationDegrees),
                setFor: setFor,
                setBy: setBy
            )
            
            self.processedReminders.append(annotation)
        }
        
        return self.processedReminders
        
    }
    
    
}