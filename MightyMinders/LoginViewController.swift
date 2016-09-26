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
    
    func touchesBegan(touches: Set<UITouch>, with: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: with)
    }
    
    func validate() -> Bool {
        if (emailFld.text == nil) || (passFld.text == nil) {
            
            let loginError = UIAlertController(title: "Error", message: "Both fields are required to login", preferredStyle: UIAlertControllerStyle.alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            loginError.addAction(OKAction)
            self.present(loginError, animated: true, completion: nil)
            return false
            
        } else {
            return true
        }
    }
    
    // MARK: Login action
    @IBAction func login() {
        activity.isHidden = false
        if validate() {
            FIRAuth.auth()?.signIn(withEmail: emailFld.text!, password: passFld.text!, completion: { (user, error) in
                if error != nil {
                    // There was an error logging in to this account
                    self.errorTxt.isHidden = false
                    if let errorCode = FIRAuthErrorCode(rawValue: error!._code) {
                        
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
                    self.ref.child("devices").child((user?.uid)!).setValue(["token": FIRInstanceID.instanceID().token()!])
                    self.dismiss(animated: true, completion: nil)
                }
                self.activity.isHidden = true
            })
        }
    
    }
    
    // MARK: Forgot password action
    @IBAction func forgetPasswdAction(sender: AnyObject) {
        
        if emailFld.text != "" {
            FIRAuth.auth()?.sendPasswordReset(withEmail: emailFld.text!, completion: { (error) in
                if error != nil {
                    // There was an error processing the request
                    let passwdError = UIAlertController(title: "Error", message: "There was an error resetting your password, please try again.", preferredStyle: UIAlertControllerStyle.alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    passwdError.addAction(OKAction)
                    self.present(passwdError, animated: true, completion: nil)
                } else {
                    // Password reset sent successfully
                    let emailError = UIAlertController(title: "Success", message: "Please check your email for instructions on resetting your password.", preferredStyle: UIAlertControllerStyle.alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    emailError.addAction(OKAction)
                    self.present(emailError, animated: true, completion: nil)
                }
            })
        } else {
            let emailError = UIAlertController(title: "Error", message: "Please enter your email address and click \"I forgot my password\" again.", preferredStyle: UIAlertControllerStyle.alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            emailError.addAction(OKAction)
            self.present(emailError, animated: true, completion: nil)
        }
        
        
        
    }
    
}
