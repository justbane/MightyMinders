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
    
    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    // MARK: Friends getters
    func getFriends(uid: String, completion:(friendsData: FDataSnapshot) -> Void) {
        // Get friends
        let canRemindFriends = ref.childByAppendingPath("users/\(uid)")
        canRemindFriends.observeEventType(.Value, withBlock: { snapshot in
            completion(friendsData: snapshot)
        })
    }
    
    func getFriendKeysICanRemind(completion: (friendsToRemind: FDataSnapshot) -> Void) {
        // Get friend keys
        let canRemindKeys = ref.childByAppendingPath("friends/\(ref.authData.uid)/can-remind")
        canRemindKeys.observeEventType(.Value, withBlock: { (snapshot) -> Void in
            completion(friendsToRemind: snapshot)
        })
        
    }
    
    func getFriendKeysThatRemindMe(completion:(friendsRemindMe: FDataSnapshot) -> Void) {
        // Get friend keys
        let canRemindKeys = ref.childByAppendingPath("friends/\(ref.authData.uid)/remind-me")
        canRemindKeys.observeEventType(.Value, withBlock: { (snapshot) -> Void in
            completion(friendsRemindMe: snapshot)
        })
    }
    
    // MARK: Remove friends
    func removeFriendAccess(uid: String) {
        let remindMeRef = ref.childByAppendingPath("friends/\(ref.authData.uid)/remind-me/\(uid)")
        remindMeRef.removeValue()
    }
    
    func removeMeFromCanRemindList(uid: String) {
        let canRemindRef = ref.childByAppendingPath("friends/\(uid)/can-remind/\(ref.authData.uid)")
        canRemindRef.removeValue()
    }
    
    // MARK: Allow friends
    func addAllowedFriends(uid: String, completion:(error: Bool) -> Void) {
        let remindMeRef = ref.childByAppendingPath("friends/\(ref.authData.uid)/remind-me")
        remindMeRef.updateChildValues([uid: "true"] as [NSObject : AnyObject], withCompletionBlock: { (error: NSError?, ref: Firebase!) in
            if error != nil {
                completion(error: true)
            }
        })
    }
    
    func addToCanRemindFriends(uid: String, completion:(error: Bool) -> Void) {
        let canRemindRef = ref.childByAppendingPath("friends/\(uid)/can-remind")
        canRemindRef.updateChildValues([ref.authData.uid: "true"] as [NSObject : AnyObject], withCompletionBlock: { (error: NSError?, ref: Firebase!) in
            if error != nil {
                completion(error: true)
            }
        })
    }
    
    // MARK: Search friends
    func searchFriendsByEmail(emailString: String, completion:(usersFound: FDataSnapshot) -> Void) {
        let usersRef = ref.childByAppendingPath("users")
        usersRef.queryOrderedByChild("email_address").queryStartingAtValue("\(emailString)").queryEndingAtValue("\(emailString)~").observeEventType(.Value, withBlock: { snapshot in
            completion(usersFound: snapshot)
        })
    }

    
    // End class
}