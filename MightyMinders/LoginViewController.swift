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
    let userDefaults = UserDefaults.standard
    
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
        activity.isHidden = true
        if let error = errorTxt {
            error.isHidden = true;
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if FIRAuth.auth()?.currentUser != nil {
            // User authenticated with Firebase
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    // MARK: Login action
    @IBAction func doLogin(_ sender: AnyObject) {
        activity.isHidden = false
        FIRAuth.auth()?.signIn(withEmail: emailFld.text!, password: passFld.text!, completion: { (user, error) in
            if error != nil {
                // There was an error logging in to this account
                self.errorTxt.isHidden = false
                if let errorCode = FIRAuthErrorCode(rawValue: error!.code) {
                    
                    switch(errorCode) {
                        
                    case .errorCodeUserNotFound:
                        self.errorTxt.text = "Error: Invalid user"
                        
                    case .errorCodeInvalidCredential:
                        self.errorTxt.text = "Error: Invalid email or password"
                        
                    case .errorCodeInvalidEmail:
                        self.errorTxt.text = "Error: Invalid email or password"
                        
                    case .errorCodeWrongPassword:
                        self.errorTxt.text = "Error: Invalid email or password"
                        
                    default:
                        self.errorTxt.text = "Error: unknown error"
                        
                    }
                }
            } else {
                // We are now logged in
                // Update device token
                self.ref.child("devices").child((FIRAuth.auth()?.currentUser?.uid)!).setValue(["token": FIRInstanceID.instanceID().token()!])
                
                self.dismiss(animated: true, completion: nil)
            }
            self.activity.isHidden = true
        })
        
    }
    
    // MARK: Forgot password action
    @IBAction func forgetPasswdAction(_ sender: AnyObject) {
        
        if emailFld.text != "" {
            FIRAuth.auth()?.sendPasswordReset(withEmail: emailFld.text!, completion: { (error) in
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
