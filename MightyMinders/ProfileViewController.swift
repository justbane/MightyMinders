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
    
    override func viewWillAppear(_ animated: Bool) {
        // Check for valid user
        
        // Show activity
        profileActivity.startAnimating()
        profileActivity.isHidden = false
        
        if FIRAuth.auth()?.currentUser == nil {
            super.showLogin()
        } else {
            // Get user data to fields
            usersRef = ref.child("users").child((FIRAuth.auth()?.currentUser?.uid)!).observe(FIRDataEventType.value, with: { (snapshot) -> Void in
                // set reminders object
                let results = snapshot.value as! [String: AnyObject]
                self.firstNameFld.text = results["first_name"] as? String
                self.lastNameFld.text = results["last_name"] as? String
                self.emailFld.text = results["email_address"] as? String
                
                self.user = Users(currentEmail: self.emailFld.text! as String, currentFirstName: self.firstNameFld.text! as String, currentLastName: self.lastNameFld.text! as String)
                
                // hide the activity
                self.profileActivity.stopAnimating()
                self.profileActivity.isHidden = true;
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        // Remove observer
        ref.removeObserver(withHandle: usersRef)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    @IBAction func saveProfileData(_ sender: AnyObject) {
        
        if newPasswdFld.text == "" {
            
            if emailFld.text != user.currentEmail {
                // Check for passwd
                if currPasswdFld.text == "" {
                    
                    let passwdError = UIAlertController(title: "Error", message: "Please enter your current password to change your email", preferredStyle: UIAlertControllerStyle.alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    passwdError.addAction(OKAction)
                    self.present(passwdError, animated: true, completion: nil)
                
                } else {
                    // Change email for user
                    user.changeEmailForUser(currPasswdFld.text!, newEmail: emailFld.text!) {(error: (Bool, String)) in
                        var msg = ""
                        var title = ""
                        if error.0 {
                            title = "Error"
                            msg = "This is a sensitive operation and requires recent authentication. Please logout and back in and try again."
                        } else {
                            title = "Success"
                            msg = "Your email has been updated!"
                            self.currPasswdFld.text = ""
                        }
                        
                        let emailMsg = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        emailMsg.addAction(OKAction)
                        self.present(emailMsg, animated: true, completion: nil)
                    }
                    
                }
                
            } else {
                // Update Profile information for user
                user.currentEmail = emailFld.text!
                user.currentFirstName = firstNameFld.text!
                user.currentLastName = lastNameFld.text!
                user.updateProfileData({ (error) -> Void in
                    if !error {
                        let profileMsg = UIAlertController(title: "Success!", message: "Your profile information has been updated.", preferredStyle: UIAlertControllerStyle.alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        profileMsg.addAction(OKAction)
                        self.present(profileMsg, animated: true, completion: nil)
                        
                    }
                })
            }

        }
        
        // Passwd reset
        if currPasswdFld.text != "" && newPasswdFld.text != "" {
            
            // Update passwd
            user.changeUserPassword(currPasswdFld.text!, newPassword: newPasswdFld.text!, completion: { (error) -> Void in
                var title = ""
                var msg = ""
                if error {
                    // There was an error processing the request
                    title = "Error"
                    msg = "There was an error changing your password"
                } else {
                    // Password changed successfully
                    title = "Success!"
                    msg = "Your password has been changed."
                    self.currPasswdFld.text = ""
                    self.newPasswdFld.text = ""
                }
                
                let passwdMsg = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                passwdMsg.addAction(OKAction)
                self.present(passwdMsg, animated: true, completion: nil)
            })
            
        }
        
    }
    
    @IBAction func logoutAction(_ sender: UIButton) {
        
        // Kill firebase session
        do {
            try FIRAuth.auth()!.signOut()
        } catch FIRAuthErrorCode.errorCodeKeychainError {
            print("Keychain Error")
        } catch {
            print("Unknown Error")
        }
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func closeBtnAction(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

}
