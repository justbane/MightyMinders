//
//  Friends.swift
//  MightyMinders
//
//  Created by Justin Bane on 3/20/16.
//  Copyright © 2016 Justin Bane. All rights reserved.
//

import Foundation

protocol Friend {}

class Friends: Friend {
    
    let ref = FIRDatabase.database().reference()
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    // MARK: Friends getters
    func getFriends(uid: String, completion:(friendsData: FIRDataSnapshot) -> Void) {
        // Get friends
        let canRemindFriends = ref.child("users").child(uid)
        canRemindFriends.observeEventType(.Value, withBlock: { snapshot in
            completion(friendsData: snapshot)
        })
    }
    
    func getFriendKeysICanRemind(completion: (friendsToRemind: FIRDataSnapshot) -> Void) {
        // Get friend keys
        let canRemindKeys = ref.child("friends").child((FIRAuth.auth()?.currentUser?.uid)!).child("can-remind")
        canRemindKeys.observeEventType(.Value, withBlock: { (snapshot) -> Void in
            completion(friendsToRemind: snapshot)
        })
        
    }
    
    func getFriendKeysThatRemindMe(completion:(friendsRemindMe: FIRDataSnapshot) -> Void) {
        // Get friend keys
        let canRemindKeys = ref.child("friends").child((FIRAuth.auth()?.currentUser?.uid)!).child("remind-me")
        canRemindKeys.observeEventType(.Value, withBlock: { (snapshot) -> Void in
            completion(friendsRemindMe: snapshot)
        })
    }
    
    // MARK: Remove friends
    func removeFriendAccess(uid: String) {
        let remindMeRef = ref.child("friends").child((FIRAuth.auth()?.currentUser?.uid)!).child("remind-me").child(uid)
        remindMeRef.removeValue()
    }
    
    func removeMeFromCanRemindList(uid: String) {
        let canRemindRef = ref.child("friends").child(uid).child("can-remind").child((FIRAuth.auth()?.currentUser?.uid)!)
        canRemindRef.removeValue()
    }
    
    // MARK: Allow friends
    func addAllowedFriends(uid: String, completion:(error: Bool) -> Void) {
        let remindMeRef = ref.child("friends").child((FIRAuth.auth()?.currentUser?.uid)!).child("remind-me")
        remindMeRef.updateChildValues([uid: "true"] as [NSObject : AnyObject], withCompletionBlock: { (error: NSError?, ref: FIRDatabaseReference!) in
            if error != nil {
                completion(error: true)
            }
        })
    }
    
    func addToCanRemindFriends(uid: String, completion:(error: Bool) -> Void) {
        let canRemindRef = ref.child("friends").child(uid).child("can-remind")
        canRemindRef.updateChildValues([(FIRAuth.auth()?.currentUser?.uid)!: "true"] as [NSObject : AnyObject], withCompletionBlock: { (error: NSError?, ref: FIRDatabaseReference!) in
            if error != nil {
                completion(error: true)
            }
        })
    }
    
    // MARK: Search friends
    func searchFriendsByEmail(emailString: String, completion:(usersFound: FIRDataSnapshot) -> Void) {
        let usersRef = ref.child("users")
        usersRef.queryOrderedByChild("email_address").queryStartingAtValue("\(emailString)").queryEndingAtValue("\(emailString)~").observeEventType(.Value, withBlock: { snapshot in
            completion(usersFound: snapshot)
        })
    }

    
    // End class
}