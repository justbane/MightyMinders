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
    let userDefaults = UserDefaults.standard
    
    // MARK: Friends getters
    func getFriends(_ uid: String, completion:@escaping (_ friendsData: FIRDataSnapshot) -> Void) {
        // Get friends
        let canRemindFriends = ref.child("users").child(uid)
        canRemindFriends.observe(.value, with: { snapshot in
            completion(snapshot)
        })
    }
    
    func getFriendKeysICanRemind(_ completion: @escaping (_ friendsToRemind: FIRDataSnapshot) -> Void) {
        // Get friend keys
        let canRemindKeys = ref.child("friends").child((FIRAuth.auth()?.currentUser?.uid)!).child("can-remind")
        canRemindKeys.observe(.value, with: { (snapshot) -> Void in
            completion(snapshot)
        })
        
    }
    
    func getFriendKeysThatRemindMe(_ completion:@escaping (_ friendsRemindMe: FIRDataSnapshot) -> Void) {
        // Get friend keys
        let canRemindKeys = ref.child("friends").child((FIRAuth.auth()?.currentUser?.uid)!).child("remind-me")
        canRemindKeys.observe(.value, with: { (snapshot) -> Void in
            completion(snapshot)
        })
    }
    
    // MARK: Remove friends
    func removeFriendAccess(_ uid: String) {
        let remindMeRef = ref.child("friends").child((FIRAuth.auth()?.currentUser?.uid)!).child("remind-me").child(uid)
        remindMeRef.removeValue()
    }
    
    func removeMeFromCanRemindList(_ uid: String) {
        let canRemindRef = ref.child("friends").child(uid).child("can-remind").child((FIRAuth.auth()?.currentUser?.uid)!)
        canRemindRef.removeValue()
    }
    
    // MARK: Allow friends
    func addAllowedFriends(_ uid: String, completion:@escaping (_ error: Bool) -> Void) {
        let remindMeRef = ref.child("friends").child((FIRAuth.auth()?.currentUser?.uid)!).child("remind-me")
        remindMeRef.updateChildValues([uid: "true"] as [AnyHashable: Any], withCompletionBlock: { (error: Error?, ref: FIRDatabaseReference!) in
            if error != nil {
                completion(true)
            }
        })
    }
    
    func addToCanRemindFriends(_ uid: String, completion:@escaping (_ error: Bool) -> Void) {
        let canRemindRef = ref.child("friends").child(uid).child("can-remind")
        canRemindRef.updateChildValues([(FIRAuth.auth()?.currentUser?.uid)!: "true"] as [AnyHashable: Any], withCompletionBlock: { (error: Error?, ref: FIRDatabaseReference!) in
            if error != nil {
                completion(true)
            }
        })
    }
    
    // MARK: Search friends
    func searchFriendsByEmail(_ emailString: String, completion:@escaping (_ usersFound: FIRDataSnapshot) -> Void) {
        let usersRef = ref.child("users")
        usersRef.queryOrdered(byChild: "email_address").queryStarting(atValue: "\(emailString)").queryEnding(atValue: "\(emailString)~").observe(.value, with: { snapshot in
            completion(snapshot)
        })
    }

    
    // End class
}
