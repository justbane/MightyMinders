//
//  Users.swift
//  MightyMinders
//
//  Created by Justin Bane on 1/24/16.
//  Copyright © 2016 Justin Bane. All rights reserved.
//

import Foundation
import AeroGearPush

protocol User {}

class Users: User {
    
    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    var currentEmail: String
    var currentFirstName: String
    var currentLastName: String
    
    init(currentEmail: String, currentFirstName: String, currentLastName: String) {
        
        self.currentEmail = currentEmail
        self.currentFirstName = currentFirstName
        self.currentLastName = currentLastName
        
    }
    
    // MARK: Change email for user
    func changeEmailForUser(password: String, newEmail: String, completion: (error: Bool) -> Void) {
        
        // Change user email
        ref.changeEmailForUser(self.currentEmail, password: password, toNewEmail: newEmail, withCompletionBlock: { error in
            
                if error != nil {
                    // There was an error processing the request
                    completion(error: true)
                } else {
                    // Email changed successfully
                    self.currentEmail = newEmail
                    self.updateProfileData({ (error) -> Void in
                        if error {
                            // FIXME: alert an error
                        }
                    })
                    completion(error: false)
                }
        
        })
        
    }
    
    // MARK: Uodate user profile
    func updateProfileData(completion: (error: Bool) -> Void) {
        
        let dataToUpdate = [
            "email_address": currentEmail,
            "first_name": currentFirstName,
            "last_name": currentLastName
        ]
        
        let profileRef = self.ref.childByAppendingPath("users/\(ref.authData.uid)")
        profileRef.setValue(dataToUpdate)
        
        // Update the APNS alias
        APNS().updateAlias(dataToUpdate["email_address"]!)
        
        completion(error: false)
        
    }
    
    // MARK: Update user password
    func changeUserPassword(oldPassword: String, newPassword: String, completion: (error: Bool) -> Void) {
        
        ref.changePasswordForUser(self.currentEmail, fromOld: oldPassword,
            toNew: newPassword, withCompletionBlock: { error in
                if error != nil {
                    completion(error: true)
                } else {
                    completion(error: false)
                }
        })
        
    }
    
    // End Class
}