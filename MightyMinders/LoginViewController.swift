//
//  LoginViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 4/23/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    let ref = FIRDatabase.database().reference()
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet weak var emailFld: UITextField!
    @IBOutlet weak var passFld: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var errorTxt: UILabel!
    @IBOutlet weak var forgotPasswd: UIButton!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        activity.hidden = true
        if let error = errorTxt {
            error.hidden = true;
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        if FIRAuth.auth()?.currentUser != nil {
            // User authenticated with Firebase
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    // MARK: Login action
    @IBAction func doLogin(sender: AnyObject) {
        activity.hidden = false
        FIRAuth.auth()?.signInWithEmail(emailFld.text!, password: passFld.text!, completion: { (user, error) in
            if error != nil {
                // There was an error logging in to this account
                self.errorTxt.hidden = false
                if let errorCode = FIRAuthErrorCode(rawValue: error!.code) {
                    
                    switch(errorCode) {
                        
                    case .ErrorCodeUserNotFound:
                        self.errorTxt.text = "Error: Invalid user"
                        
                    case .ErrorCodeInvalidCredential:
                        self.errorTxt.text = "Error: Invalid email or password"
                        
                    case .ErrorCodeInvalidEmail:
                        self.errorTxt.text = "Error: Invalid email or password"
                        
                    case .ErrorCodeWrongPassword:
                        self.errorTxt.text = "Error: Invalid email or password"
                        
                    default:
                        self.errorTxt.text = "Error: unknown error"
                        
                    }
                }
            } else {
                // We are now logged in
                // Update device token
                self.ref.child("devices").child((FIRAuth.auth()?.currentUser?.uid)!).setValue(["token": FIRInstanceID.instanceID().token()!])
                
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            self.activity.hidden = true
        })
        
    }
    
    // MARK: Forgot password action
    @IBAction func forgetPasswdAction(sender: AnyObject) {
        
        if emailFld.text != "" {
            FIRAuth.auth()?.sendPasswordResetWithEmail(emailFld.text!, completion: { (error) in
                if error != nil {
                    // There was an error processing the request
                    let passwdError = UIAlertView(title: "Error", message: "There was an error resetting your password, please try again.", delegate: nil, cancelButtonTitle: "OK")
                    passwdError.show()
                } else {
                    // Password reset sent successfully
                    let emailError = UIAlertView(title: "Success", message: "Plesae check your email for instructions on resetting your password.", delegate: nil, cancelButtonTitle: "OK")
                    emailError.show()
                }
            })
        } else {
            let emailError = UIAlertView(title: "Error", message: "Please enter your email address and click \"I forgot my password\" again.", delegate: nil, cancelButtonTitle: "OK")
            emailError.show()
        }
        
        
        
    }
    
}
