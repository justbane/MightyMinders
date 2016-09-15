//
//  Minders.swift
//  MightyMinders
//
//  Created by Justin Bane on 9/10/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import Foundation
import MapKit

protocol Minder {}

class Minders: Minder {
    
    let ref = FIRDatabase.database().reference()
    let userDefaults = UserDefaults.standard
    
    var processedReminders = Set<Annotation>()
    
    // MARK: The minder getters
    func getPrivateMinders(_ completion:@escaping (_ privateReminders: FIRDataSnapshot) -> Void) {
        
        // Private minders
        let userMindersRef = ref.child("minders").child((FIRAuth.auth()?.currentUser?.uid)!).child("private")
        
        // Listen for add of new minders
        userMindersRef.observe(.value, with: { (snapshot) -> Void in
            completion(snapshot)
        })

        
    }
    
    func getSharedReminders(_ completion:@escaping (_ sharedReminders: FIRDataSnapshot) -> Void) {
        
        let sharedMindersRef = ref.child("shared-minders")
        
        // Listen for add of new minders
        // Set for you
        sharedMindersRef.queryOrdered(byChild: "set-for").queryEqual(toValue: (FIRAuth.auth()?.currentUser?.uid)!).observe(.value, with: { (snapshot) -> Void in
            completion(snapshot)
        })

        
    }
    
    // MARK: Listeners for removals
    func getRemindersSetByYou(_ completion:@escaping (_ remindersSetByYou: FIRDataSnapshot) -> Void) {
        
        let sharedMindersRef = ref.child("shared-minders")
        
        sharedMindersRef.queryOrdered(byChild: "set-by").queryEqual(toValue: (FIRAuth.auth()?.currentUser?.uid)!).observe(.value, with: { (snapshot) -> Void in
            completion(snapshot)
        })
        
    }
    
    func listenForRemindersRemovedForMe(_ completion:@escaping (_ remindersRemovedForMe: FIRDataSnapshot) -> Void) {
        
        let sharedMindersRef = ref.child("shared-minders")
        
        sharedMindersRef.queryOrdered(byChild: "set-for").queryEqual(toValue: (FIRAuth.auth()?.currentUser?.uid)!).observe(.childRemoved, with: { (snapshot) -> Void in
            completion(snapshot)
        })
    }
    
    func listenForRemindersRemovedByMe(_ completion:@escaping (_ remindersRemovedByMe: FIRDataSnapshot) -> Void) {
        
        let sharedMindersRef = ref.child("shared-minders")
        
        sharedMindersRef.queryOrdered(byChild: "set-by").queryEqual(toValue: (FIRAuth.auth()?.currentUser?.uid)!).observe(.childRemoved, with: { (snapshot) -> Void in
            completion(snapshot)
        })
    }
    
    // MARK: Process Minders
    func processMinders(_ reminderSubData: FIRDataSnapshot, type: String) -> Set<Annotation> {
        
        let enumerator = reminderSubData.children
        while let data = enumerator.nextObject() as? FIRDataSnapshot {
            
            // Add reminders to map
            let pinLocation = (data.value! as AnyObject).value(forKey: "location") as! NSDictionary
            
            var timing = 0
            if let FBTiming = (data.value! as AnyObject).value(forKey: "timing") as? Int {
                timing = FBTiming
            }
            
            var setFor = ""
            if (data.value! as AnyObject).value(forKey: "set-for") !== nil {
                setFor = (data.value! as AnyObject).value(forKey: "set-for") as! String
            }
            
            var setBy = ""
            if (data.value! as AnyObject).value(forKey: "set-by") !== nil {
                setBy = (data.value! as AnyObject).value(forKey: "set-by") as! String
            }
            
            var address = "";
            if pinLocation.value(forKey: "address") == nil {
                address = "Unknown Address"
            } else {
                address = pinLocation.value(forKey: "address") as! String
            }
            
            let annotation = Annotation(
                key: data.key,
                title: pinLocation.value(forKey: "name") as! String,
                subtitle: address,
                content: (data.value! as AnyObject).value(forKey: "content") as! String,
                type: type,
                event: timing,
                coordinate: CLLocationCoordinate2D(
                    latitude: pinLocation.value(forKey: "latitude") as! CLLocationDegrees,
                    longitude: pinLocation.value(forKey: "longitude") as! CLLocationDegrees),
                setFor: setFor,
                setBy: setBy
            )
            
            self.processedReminders.insert(annotation)
        }
        
        return self.processedReminders
    
    }
    
    // MARK: Add Reminder
    func addReminder(_ content: String, location: [String: AnyObject], timing: Int, setBy: String, setFor: String , completion: @escaping (_ returnedMinder: NSDictionary, _ error: Bool) -> Void) {
        
        let reminder = [
            "content": content,
            "location": location,
            "timing": timing,
            "set-by": setBy,
            "set-for": setFor
        ] as [String : Any]
        
        // Set the ref path
        var usersMindersRef = ref.child("minders").child((FIRAuth.auth()?.currentUser?.uid)!).child("private")
        
        // Is there a friend selected?
        if setBy != setFor {
            usersMindersRef = ref.child("shared-minders")
            
        }
        
        let usersMindersRefAuto = usersMindersRef.childByAutoId()
            usersMindersRefAuto.setValue(reminder, withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
                if error != nil {
                    completion(returnedMinder: reminder, error: true)
                } else {
                    completion(returnedMinder: reminder, error: false)
                }
            })
    }
    
    // MARK: Edit Reminder
    func editReminder(_ identifier: String, content: String, location: [String: AnyObject], timing: Int, setBy: String, setFor: String , completion: @escaping (_ returnedMinder: NSDictionary, _ error: Bool) -> Void) {
        
        let reminder = [
            "content": content,
            "location": location,
            "timing": timing,
            "set-by": setBy,
            "set-for": setFor
        ] as [String : Any]
        
        // Set the ref path
        var usersMindersRef = ref.child("minders").child((FIRAuth.auth()?.currentUser?.uid)!).child("private").child(identifier)
        
        // Is there a friend selected?
        if setBy != setFor {
            // Is there a friend and we are editing?
            usersMindersRef = ref.child("shared-minders").child(identifier)
        }
        
        usersMindersRef.updateChildValues(reminder as [AnyHashable: Any], withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
            if error != nil {
                completion(returnedMinder: reminder, error: true)
            } else {
                completion(returnedMinder: reminder, error: false)
            }
        })
        
        if setBy != setFor {
            let usersMinderRemove = ref.child("minders").child((FIRAuth.auth()?.currentUser?.uid)!).child("private").child(identifier)
            usersMinderRemove.removeValue()
        }

    }
    
    // MARK: Send Reminder Notification
    func sendReminderNotification(_ userMinder: NSDictionary) {
        
        if (FIRAuth.auth()?.currentUser?.uid)! as String != userMinder["set-for"] as! String {
            
            let restReq = HTTPRequests()
            let setBy = userMinder["set-by"] as! String
            let setFor = userMinder["set-for"] as! String
            let content = userMinder["content"] as! String
            let location = userMinder["location"]!
            var token: String = ""
            var senderName: String = "Someone"
            
            // Get sender profile data
            let setByRef = self.ref.child("users").child(setBy)
            setByRef.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
                let first_name: String = (snapshot.value! as AnyObject).object(forKey: "first_name") as! String
                let last_name: String = (snapshot.value! as AnyObject).object(forKey: "last_name") as! String
                senderName = "\(first_name) \(last_name)"
                
                // Get reciever device token
                self.ref.child("devices").child(setFor).observe(.value, with: { (snapshot) in
                    if snapshot.value != nil {
                        token = (snapshot.value! as AnyObject).object(forKey: "token") as! String
                    }
                    
                    if token != "" {
                        let data: [String: AnyObject] = [
                            "to": token as AnyObject,
                            "notification": [
                                "title": "New MightyMinder",
                                "body": "\(senderName) set a reminder for you: \(content) - Swipe to update your reminders",
                            ],
                            "data": [
                                "latitude": location["latitude"]!,
                                "longitude": location["longitude"]!
                            ]
                        ]
                        
                        // Send to push server
                        restReq.sendPostRequest(data) { (success, msg) -> () in
                            // Completion code here
                            // print(success)
                            
                            let status = msg["status"] as! String
                            if status.contains("FAILURE") {
                                print(status)
                            }
                        }
                    }
                })
                
            })
            
        }
    }
    
    
    // End Class
}
