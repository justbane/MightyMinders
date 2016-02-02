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
    
    func addUpdateReminder(minder: [String: Anyobject], completion: (error: Bool) -> Void) {
        
        let userMinder = [
            "content": minder["content"],
            "location": minder["location"],
            "timing": minder["timing"],
            "set-by": minder["set-by"],
            "set-for": minder["set-for"]
        ]
        
        // set the ref path
        var usersMindersRef = ref.childByAppendingPath("minders/\(ref.authData.uid)/private")
        
        // are we editing?
        if identifier != nil {
            usersMindersRef = ref.childByAppendingPath("minders/\(ref.authData.uid)/private/\(identifier)")
        }
        
        // is there a friend selected?
        if friends.count > 0 {
            usersMindersRef = ref.childByAppendingPath("shared-minders")
            
            // is there a friend and we are editing?
            if identifier != nil {
                usersMindersRef = ref.childByAppendingPath("shared-minders/\(identifier)")
            }
            
        }
        
        if identifier != nil {
            usersMindersRef.updateChildValues(userMinder as [NSObject : AnyObject], withCompletionBlock: { (error:NSError?, ref:Firebase!) in
                if error {
                    completion(error: true)
                }
            })
            
            // remove minder from private if adding a friend
            if (friends.count > 0 && friends["id"] as! String != ref.authData.uid as String) {
                let usersMinderRemove = ref.childByAppendingPath("minders/\(ref.authData.uid)/private/\(identifier)")
                usersMinderRemove.removeValue()
                // self.sendReminderNotification(userMinder)
            }
            
        } else {
            let usersMindersRefAuto = usersMindersRef.childByAutoId()
            usersMindersRefAuto.setValue(userMinder, withCompletionBlock: { (error:NSError?, ref:Firebase!) in
                if error != nil {
                    completion(error: true)
                }
            })
        }
        
    }
    
    
}