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
            
            let itemData = data.value as! [String: AnyObject]
            
            // Add reminders to map
            let pinLocation = itemData["location"] as! NSDictionary
            
            var timing = 0
            if let FBTiming = itemData["timing"] as? Int {
                timing = FBTiming
            }
            
            var setFor = ""
            if itemData["set-for"] != nil {
                setFor = itemData["set-for"] as! String
            }
            
            var setBy = ""
            if itemData["set-by"] != nil {
                setBy = itemData["set-by"] as! String
            }
            
            var address = "";
            if pinLocation["address"] == nil {
                address = "Unknown Address"
            } else {
                address = pinLocation["address"] as! String
            }
            
            let annotation = Annotation(
                key: data.key,
                title: pinLocation["name"] as! String,
                subtitle: address,
                content: itemData["content"] as! String,
                type: type,
                event: timing,
                coordinate: CLLocationCoordinate2D(
                    latitude: pinLocation["latitude"] as! CLLocationDegrees,
                    longitude: pinLocation["longitude"] as! CLLocationDegrees),
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
            usersMindersRefAuto.setValue(reminder, withCompletionBlock: { (error:Error?, ref:FIRDatabaseReference!) in
                if error != nil {
                    completion(reminder as NSDictionary, true)
                } else {
                    completion(reminder as NSDictionary, false)
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
        
        usersMindersRef.updateChildValues(reminder as [AnyHashable: Any], withCompletionBlock: { (error:Error?, ref:FIRDatabaseReference!) in
            if error != nil {
                completion(reminder as NSDictionary, true)
            } else {
                completion(reminder as NSDictionary, false)
            }
        })
        
        if setBy != setFor {
            let usersMinderRemove = ref.child("minders").child((FIRAuth.auth()?.currentUser?.uid)!).child("private").child(identifier)
            usersMinderRemove.removeValue()
        }

    }
    
    // MARK: Set local notification
    func setNotifications(annotation: Annotation, region: CLCircularRegion) {
        if annotation.setFor == (FIRAuth.auth()?.currentUser?.uid)! {
            let ln:UILocalNotification = UILocalNotification()
            ln.alertAction = annotation.title
            ln.alertBody = annotation.content
            ln.region = region
            ln.regionTriggersOnce = false
            ln.soundName = "MightyMindersJingle.aif"
            UIApplication.shared.scheduleLocalNotification(ln)
        }
        
    }
    
    // MARK: Send Reminder Notification
    func sendReminderNotification(_ userMinder: NSDictionary) {
        
        if (FIRAuth.auth()?.currentUser?.uid)! as String != userMinder["set-for"] as! String {
            
            let restReq = HTTPRequests()
            let setBy = userMinder["set-by"] as! String
            let setFor = userMinder["set-for"] as! String
            let content = userMinder["content"] as! String
            let location = userMinder["location"] as! [String: Any]
            var token: String = ""
            var senderName: String = "Someone"
            
            // Get sender profile data
            let setByRef = self.ref.child("users").child(setBy)
            setByRef.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
                let userData = snapshot.value as! [String: AnyObject]
                let first_name: String = userData["first_name"] as! String
                let last_name: String = userData["last_name"] as! String
                senderName = "\(first_name) \(last_name)"
                
                // Get reciever device token
                self.ref.child("devices").child(setFor).observe(.value, with: { (snapshot) in
                    let device = snapshot.value as! [String: AnyObject]
                    if device["token"] != nil {
                        token = device["token"] as! String
                        let data = [
                            "to": token,
                            "notification": [
                                "title": "New MightyMinder",
                                "body": "\(senderName) set a reminder for you: \(content) - Swipe to update your reminders",
                            ],
                            "data": [
                                "latitude": location["latitude"]!,
                                "longitude": location["longitude"]!
                            ]
                            ] as [String : Any]
                        
                        // Send to push server
                        restReq.sendPostRequest(data as [String : AnyObject]) { (success, msg) -> () in
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
