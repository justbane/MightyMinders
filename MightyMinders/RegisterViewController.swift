//
//  RegisterViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 4/26/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {

    let ref = Firebase(url: "https://mightyminders.firebaseio.com")
    
    @IBOutlet weak var emailFld: UITextField!
    @IBOutlet weak var passFld: UITextField!
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var errorTxt: UILabel!
    @IBOutlet weak var fnameFld: UITextField!
    @IBOutlet weak var lnameFld: UITextField!
    
    @IBOutlet weak var blueView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // set the background color
        // let background = Colors(colorString: "blue").getGradient()
        // background.frame = self.view.bounds
        // blueView.layer.insertSublayer(background, atIndex: 0)
        
        errorTxt!.hidden = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    func validate() -> Bool {
        
        var error = false
        
        if fnameFld.text!.isEmpty {
            fnameFld.layer.borderWidth = 1.0 as CGFloat
            fnameFld.layer.borderColor = UIColor.redColor().CGColor
            error = true;
        }
        
        if lnameFld.text!.isEmpty {
            lnameFld.layer.borderWidth = 1.0 as CGFloat
            lnameFld.layer.borderColor = UIColor.redColor().CGColor
            error = true;
        }
        
        if passFld.text!.isEmpty {
            passFld.layer.borderWidth = 1.0 as CGFloat
            passFld.layer.borderColor = UIColor.redColor().CGColor
            error = true;
        }
        
        if emailFld.text!.isEmpty {
            emailFld.layer.borderWidth = 1.0 as CGFloat
            emailFld.layer.borderColor = UIColor.redColor().CGColor
            error = true;
        }
        
        if error {
            return false
        }
        
        return true
    }
    
    @IBAction func doRegistration(sender: AnyObject) {
        
        if (validate() && ref.authData == nil) {
            ref.createUser(emailFld.text, password: passFld.text,
                withValueCompletionBlock: { error, result in
                    
                    if error != nil {
                        self.errorTxt.hidden = false
                        
                        if let errorCode = FAuthenticationError(rawValue: error.code) {
                            
                            switch(errorCode) {
                                
                            case .EmailTaken:
                                self.errorTxt.text = "Error: This email is already in use!"
                                self.emailFld.layer.borderWidth = 1.0 as CGFloat
                                self.emailFld.layer.borderColor = UIColor.redColor().CGColor
                                
                            case .InvalidEmail:
                                self.errorTxt.text = "Error: This email is invalid. Please follow the user@domain.com format."
                                self.emailFld.layer.borderWidth = 1.0 as CGFloat
                                self.emailFld.layer.borderColor = UIColor.redColor().CGColor
                                
                            default:
                                self.errorTxt.text = "Error: Unknown Error!"
                                
                            }
                            
                        }
                        
                    } else {
                        
                        if let _ = result["uid"] as? String {
                            
                            self.ref.authUser(self.emailFld.text, password: self.passFld.text, withCompletionBlock: { error, authData in
                                
                                if error != nil {
                                    // There was an error logging in to this account
                                } else {
                                    // We are now logged in
                                    self.saveProfileData()
                                }
                                
                            })
                            
                        }
                        
                    }
                    
            })
        } else {
            saveProfileData()
        }
    }
    
    func saveProfileData() {
        
        if(ref.authData != nil) {
            
            let userProfileData = ["first_name": self.fnameFld.text!, "last_name": self.lnameFld.text!, "email_address": self.emailFld.text!]
            
            let usersRef = self.ref.childByAppendingPath("users/\(ref.authData.uid)")
            
            usersRef.setValue(userProfileData, withCompletionBlock: { (error, ref) in
                
                if error != nil {
                    
                    self.errorTxt?.text = "Error: Please fill in all fields!"
                    self.errorTxt.hidden = false
                    
                } else {
                    
                    self.errorTxt?.text = "Success"
                    self.errorTxt.textColor = UIColor.greenColor()
                    self.errorTxt.hidden = false
                    
                    self.dismissViewControllerAnimated(true, completion: nil)
                    
                }
                
            })
        }
        
    }

}
