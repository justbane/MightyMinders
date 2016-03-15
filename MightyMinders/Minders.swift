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
    
    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    
    var processedReminders: [Annotation] = []
    
    init() {}
    
    func processMinders(reminderSubData: FDataSnapshot, type: String) -> [Annotation] {
        
        let enumerator = reminderSubData.children
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
            
            var address = "";
            if pinLocation.valueForKey("address") == nil {
                address = "Unknown Address"
            } else {
                address = pinLocation.valueForKey("address") as! String
            }
            
            let annotation = Annotation(
                key: data.key,
                title: pinLocation.valueForKey("name") as! String,
                subtitle: address,
                content: data.value.valueForKey("content") as! String,
                type: type,
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
    
    func addReminder(content: String, location: [String: AnyObject], timing: Int, setBy: String, setFor: String , completion: (returnedMinder: NSDictionary, error: Bool) -> Void) {
        
        let reminder = [
            "content": content,
            "location": location,
            "timing": timing,
            "set-by": setBy,
            "set-for": setFor
        ]
        
        // set the ref path
        var usersMindersRef = ref.childByAppendingPath("minders/\(ref.authData.uid)/private")
        
        // is there a friend selected?
        if setBy != setFor {
            usersMindersRef = ref.childByAppendingPath("shared-minders")
            
        }
        
        let usersMindersRefAuto = usersMindersRef.childByAutoId()
            usersMindersRefAuto.setValue(reminder, withCompletionBlock: { (error:NSError?, ref:Firebase!) in
                if error != nil {
                    completion(returnedMinder: reminder, error: true)
                } else {
                    completion(returnedMinder: reminder, error: false)
                }
            })
    }
    
    func editReminder(identifier: String, content: String, location: [String: AnyObject], timing: Int, setBy: String, setFor: String , completion: (returnedMinder: NSDictionary, error: Bool) -> Void) {
        
        let reminder = [
            "content": content,
            "location": location,
            "timing": timing,
            "set-by": setBy,
            "set-for": setFor
        ]
        
        // set the ref path
        var usersMindersRef = ref.childByAppendingPath("minders/\(ref.authData.uid)/private/\(identifier)")
        
        // is there a friend selected?
        if setBy != setFor {
            // is there a friend and we are editing?
            usersMindersRef = ref.childByAppendingPath("shared-minders/\(identifier)")
        }
        
        usersMindersRef.updateChildValues(reminder as [NSObject : AnyObject], withCompletionBlock: { (error:NSError?, ref:Firebase!) in
            if error != nil {
                completion(returnedMinder: reminder, error: true)
            } else {
                completion(returnedMinder: reminder, error: false)
            }
        })
        
        if setBy != setFor {
            let usersMinderRemove = ref.childByAppendingPath("minders/\(ref.authData.uid)/private/\(identifier)")
            usersMinderRemove.removeValue()
        }

    }
    
}