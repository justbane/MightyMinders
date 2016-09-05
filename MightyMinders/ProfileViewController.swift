//
//  ProfileViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/9/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class ProfileViewController: MMCustomViewController {
    
    let ref = FIRDatabase.database().reference()
    var user: Users!
    var usersRef: UInt!
    
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var firstNameFld: MMTextField!
    @IBOutlet weak var lastNameFld: MMTextField!
    @IBOutlet weak var emailFld: MMTextField!
    @IBOutlet weak var currPasswdFld: MMTextField!
    @IBOutlet weak var newPasswdFld: MMTextField!
    @IBOutlet var logoutBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var profileActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(animated: Bool) {
        // Check for valid user
        
        // Show activity
        profileActivity.startAnimating()
        profileActivity.hidden = false
        
        if FIRAuth.auth()?.currentUser == nil {
            super.showLogin()
        } else {
            // Get user data to fields
            usersRef = ref.child("users").child((FIRAuth.auth()?.currentUser?.uid)!).observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) -> Void in
                // set reminders object
                let results = snapshot.value as! [String: AnyObject]
                self.firstNameFld.text = results["first_name"] as? String
                self.lastNameFld.text = results["last_name"] as? String
                self.emailFld.text = results["email_address"] as? String
                
                self.user = Users(currentEmail: self.emailFld.text! as String, currentFirstName: self.firstNameFld.text! as String, currentLastName: self.lastNameFld.text! as String)
                
                // hide the activity
                self.profileActivity.stopAnimating()
                self.profileActivity.hidden = true;
            })
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        // Remove observer
        ref.removeObserverWithHandle(usersRef)
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    @IBAction func saveProfileData(sender: AnyObject) {
        
        if newPasswdFld.text == "" {
            
            if emailFld.text != user.currentEmail {
                // Check for passwd
                if currPasswdFld.text == "" {
                    let passwdError = UIAlertView(title: "Error", message: "Please enter your current password to change your email", delegate: nil, cancelButtonTitle: "OK")
                    passwdError.show()
                } else {
                    // Change email for user
                    user.changeEmailForUser(currPasswdFld.text!, newEmail: emailFld.text!) {(error: (Bool, String)) in
                        if error.0 {
                            let emailError = UIAlertView(title: "Error", message: "This is a sensitive operation and requires recent authentication. Please logout and back in and try again.", delegate: nil, cancelButtonTitle: "OK")
                            emailError.show()
                        } else {
                            let emailSuccess = UIAlertView(title: "Success", message: "Your email has been updated", delegate: nil, cancelButtonTitle: "OK")
                            emailSuccess.show()
                            self.currPasswdFld.text = ""
                        }
                    }
                    
                }
                
            } else {
                // Update Profile information for user
                user.currentEmail = emailFld.text!
                user.currentFirstName = firstNameFld.text!
                user.currentLastName = lastNameFld.text!
                user.updateProfileData({ (error) -> Void in
                    if !error {
                        let profileMsg = UIAlertView(title: "Success!", message: "Your profile information has been updated.", delegate: nil, cancelButtonTitle: "OK")
                        profileMsg.show()
                    }
                })
            }

        }
        
        // Passwd reset
        if currPasswdFld.text != "" && newPasswdFld.text != "" {
            
            // Update passwd
            user.changeUserPassword(currPasswdFld.text!, newPassword: newPasswdFld.text!, completion: { (error) -> Void in
                if error {
                    // There was an error processing the request
                    let passwdError = UIAlertView(title: "Error", message: "There was an error changing your password", delegate: nil, cancelButtonTitle: "OK")
                    passwdError.show()
                } else {
                    // Password changed successfully
                    let passwdMsg = UIAlertView(title: "Success!", message: "Your password has been changed.", delegate: nil, cancelButtonTitle: "OK")
                    passwdMsg.show()
                    self.currPasswdFld.text = ""
                    self.newPasswdFld.text = ""
                }
            })
            
        }
        
    }
    
    @IBAction func logoutAction(sender: UIButton) {
        
        // Kill firebase session
        do {
            try FIRAuth.auth()!.signOut()
        } catch FIRAuthErrorCode.ErrorCodeKeychainError {
            print("Keychain Error")
        } catch {
            print("Unknown Error")
        }
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    @IBAction func closeBtnAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
