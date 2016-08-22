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
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    var processedReminders: [Annotation] = []
    
    // MARK: The minder getters
    func getPrivateMinders(completion:(privateReminders: FIRDataSnapshot) -> Void) {
        
        // Private minders
        let userMindersRef = ref.child("minders").child((FIRAuth.auth()?.currentUser?.uid)!).child("private")
        
        // Listen for add of new minders
        userMindersRef.observeEventType(.Value, withBlock: { (snapshot) -> Void in
            completion(privateReminders: snapshot)
        })

        
    }
    
    func getSharedReminders(completion:(sharedReminders: FIRDataSnapshot) -> Void) {
        
        let sharedMindersRef = ref.child("shared-minders")
        
        // Listen for add of new minders
        // Set for you
        sharedMindersRef.queryOrderedByChild("set-for").queryEqualToValue((FIRAuth.auth()?.currentUser?.uid)!).observeEventType(.Value, withBlock: { (snapshot) -> Void in
            completion(sharedReminders: snapshot)
        })

        
    }
    
    // MARK: Listeners for removals
    func getRemindersSetByYou(completion:(remindersSetByYou: FIRDataSnapshot) -> Void) {
        
        let sharedMindersRef = ref.child("shared-minders")
        
        sharedMindersRef.queryOrderedByChild("set-by").queryEqualToValue((FIRAuth.auth()?.currentUser?.uid)!).observeEventType(.Value, withBlock: { (snapshot) -> Void in
            completion(remindersSetByYou: snapshot)
        })
        
    }
    
    func listenForRemindersRemovedForMe(completion:(remindersRemovedForMe: FIRDataSnapshot) -> Void) {
        
        let sharedMindersRef = ref.child("shared-minders")
        
        sharedMindersRef.queryOrderedByChild("set-for").queryEqualToValue((FIRAuth.auth()?.currentUser?.uid)!).observeEventType(.ChildRemoved, withBlock: { (snapshot) -> Void in
            completion(remindersRemovedForMe: snapshot)
        })
    }
    
    func listenForRemindersRemovedByMe(completion:(remindersRemovedByMe: FIRDataSnapshot) -> Void) {
        
        let sharedMindersRef = ref.child("shared-minders")
        
        sharedMindersRef.queryOrderedByChild("set-by").queryEqualToValue((FIRAuth.auth()?.currentUser?.uid)!).observeEventType(.ChildRemoved, withBlock: { (snapshot) -> Void in
            completion(remindersRemovedByMe: snapshot)
        })
    }
    
    // MARK: Process Minders
    func processMinders(reminderSubData: FIRDataSnapshot, type: String) -> [Annotation] {
        
        let enumerator = reminderSubData.children
        while let data = enumerator.nextObject() as? FIRDataSnapshot {
            
            // Add reminders to map
            let pinLocation = data.value!.valueForKey("location") as! NSDictionary
            
            var timing = 0
            if let FBTiming = data.value!.valueForKey("timing") as? Int {
                timing = FBTiming
            }
            
            var setFor = ""
            if data.value!.valueForKey("set-for") !== nil {
                setFor = data.value!.valueForKey("set-for") as! String
            }
            
            var setBy = ""
            if data.value!.valueForKey("set-by") !== nil {
                setBy = data.value!.valueForKey("set-by") as! String
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
                content: data.value!.valueForKey("content") as! String,
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
    
    // MARK: Add Reminder
    func addReminder(content: String, location: [String: AnyObject], timing: Int, setBy: String, setFor: String , completion: (returnedMinder: NSDictionary, error: Bool) -> Void) {
        
        let reminder = [
            "content": content,
            "location": location,
            "timing": timing,
            "set-by": setBy,
            "set-for": setFor
        ]
        
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
    func editReminder(identifier: String, content: String, location: [String: AnyObject], timing: Int, setBy: String, setFor: String , completion: (returnedMinder: NSDictionary, error: Bool) -> Void) {
        
        let reminder = [
            "content": content,
            "location": location,
            "timing": timing,
            "set-by": setBy,
            "set-for": setFor
        ]
        
        // Set the ref path
        var usersMindersRef = ref.child("minders").child((FIRAuth.auth()?.currentUser?.uid)!).child("private").child(identifier)
        
        // Is there a friend selected?
        if setBy != setFor {
            // Is there a friend and we are editing?
            usersMindersRef = ref.child("shared-minders").child(identifier)
        }
        
        usersMindersRef.updateChildValues(reminder as [NSObject : AnyObject], withCompletionBlock: { (error:NSError?, ref:FIRDatabaseReference!) in
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
    func sendReminderNotification(userMinder: NSDictionary) {
        
        if (FIRAuth.auth()?.currentUser?.uid)! as String != userMinder["set-for"] as! String {
            
            let restReq = HTTPRequests()
            let setBy = userMinder["set-by"] as! String
            let setFor = userMinder["set-for"] as! String
            let content = userMinder["content"] as! String
            let location = userMinder["location"]!
            
            var senderName: String = "Someone"
            
            // Get sender profile data
            let setByRef = self.ref.child("users/\(setBy)")
            setByRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
                let first_name: String = snapshot.value!.objectForKey("first_name") as! String
                let last_name: String = snapshot.value!.objectForKey("last_name") as! String
                senderName = "\(first_name) \(last_name)"
                
                // Go reciever profile
                let setForRef = self.ref.child("users/\(setFor)")
                setForRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
                    let email: String = snapshot.value!.objectForKey("email_address") as! String
                    
                    let data: [String: [String: AnyObject]] = [
                        "message": [
                            "alert": "\(senderName) set a reminder for you: \(content) - Swipe to update your reminders",
                            "sound": "default",
                            "apns": [
                                "action-category": "MAIN_CATEGORY",
                                "url-args": ["\(location["latitude"]!)","\(location["longitude"]!)"]
                            ]
                        ],
                        "criteria": [
                            "alias": ["\(email)"],
                            "variants": ["\(self.userDefaults.valueForKey("variantID") as! String)"]
                        ]
                    ]
                    
                    // Send to push server
                    restReq.sendPostRequest(data, url: "https://push-baneville.rhcloud.com/ag-push/rest/sender") { (success, msg) -> () in
                        // Completion code here
                        // println(success)
                        
                        let status = msg["status"] as! String
                        if status.containsString("FAILURE") {
                            print(status)
                        }
                    }
                    
                })
                
            })
            
        }
    }
    
    
    // End Class
}