//
//  Users.swift
//  MightyMinders
//
//  Created by Justin Bane on 1/24/16.
//  Copyright © 2016 Justin Bane. All rights reserved.
//

import Foundation

protocol User {}

class Users: User {
    
    let ref = FIRDatabase.database().reference()
    let userDefaults = UserDefaults.standard
    
    var currentEmail: String
    var currentFirstName: String
    var currentLastName: String
    
    init(currentEmail: String, currentFirstName: String, currentLastName: String) {
        
        self.currentEmail = currentEmail
        self.currentFirstName = currentFirstName
        self.currentLastName = currentLastName
        
    }
    
    // MARK: Change email for user
    func changeEmailForUser(_ password: String, newEmail: String, completion: @escaping (_ error: Bool,String) -> Void) {
        
        // Change user email
        FIRAuth.auth()?.currentUser?.updateEmail(self.currentEmail, completion: { (error) in
            if error != nil {
                // There was an error processing the request
                completion(true, (error?.localizedDescription)!)
            } else {
                // Email changed successfully
                self.currentEmail = newEmail
                self.updateProfileData({ (error) -> Void in
                    if error {
                        // FIXME: alert an error
                    }
                })
                completion(false, "")
            }
        })
        
    }
    
    // MARK: Uodate user profile
    func updateProfileData(_ completion: @escaping (_ error: Bool) -> Void) {
        
        let dataToUpdate = [
            "email_address": currentEmail,
            "first_name": currentFirstName,
            "last_name": currentLastName
        ]
        
        let profileRef = self.ref.child("users").child((FIRAuth.auth()?.currentUser?.uid)!)
        profileRef.setValue(dataToUpdate) { (error, Firebase) in
            if error != nil {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    // MARK: Update user password
    func changeUserPassword(_ oldPassword: String, newPassword: String, completion: @escaping (_ error: Bool) -> Void) {
        
        FIRAuth.auth()?.currentUser?.updatePassword(self.currentEmail, completion: { (error) in
            if error != nil {
                completion(true)
            } else {
                completion(false)
            }
        })
        
    }
    
    // End Class
}
