//
//  AddReminderViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 5/6/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class AddReminderViewController: MMCustomViewController {

    let ref = FIRDatabase.database().reference()
    let userDefaults = UserDefaults.standard
    
    var selectedLocation = [String: AnyObject]()
    var selectedFriend = [String: AnyObject]()
    
    // Values from view if editing
    var reminderIdentifier: String!
    var reminderTextFromView: String!
    var reminderTimingFromView: Int!
    var reminderFriendFromView: String!
    var selectedLocationFromView = [String: AnyObject]()
    var selectedFriendFromView: String!
    
    @IBOutlet weak var screenTitleLbl: UILabel!
    @IBOutlet weak var reminderTxt: UITextView!
    @IBOutlet weak var addReminderBtn: AddRemoveButtonView!
    
    @IBOutlet weak var addLocationBtn: UIButton!
    @IBOutlet weak var addFriendBtn: UIButton!
    @IBOutlet weak var whenSelector: UISegmentedControl!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var closeBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        activity.isHidden = true
        if isModal() {
            closeBtn.isHidden = false
        }
        
        // Setup swipe down to hide keyboard
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipe.direction = UISwipeGestureRecognizerDirection.down
        self.view.addGestureRecognizer(swipe)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Check for valid user
        if FIRAuth.auth()?.currentUser == nil {
            super.showLogin()
        } else {
            // If selected friend exits
            if !selectedFriend.isEmpty {
                let first_name: String = selectedFriend["first_name"]! as! String
                let last_name: String = selectedFriend["last_name"]! as! String
                addFriendBtn.setTitle("\(first_name) \(last_name)", for: UIControlState())
            }
            
            // Setup interface values if editing a reminder
            if reminderIdentifier != nil {
                screenTitleLbl.text = "Edit Reminder"
                
                reminderTxt.text = reminderTextFromView
                whenSelector.selectedSegmentIndex = reminderTimingFromView
                selectedLocation = selectedLocationFromView
                
                if let selectedName = selectedLocationFromView["name"] as? String {
                    addLocationBtn.setTitle(selectedName, for: UIControlState())
                }
                
                if let selectedAddress = selectedLocationFromView["address"] as? String {
                    let curText = addLocationBtn.title(for: UIControlState())!
                    addLocationBtn.setTitle("\(curText) at \(selectedAddress)", for: UIControlState())
                }
                
                if !(selectedFriendFromView.isEmpty) && selectedFriendFromView != (FIRAuth.auth()?.currentUser?.uid)! {
                    ref.child("users").child(selectedFriendFromView).observeSingleEvent(of: .value, with: { (snapshot) -> Void in
                        // Set data from location controller
                        let selectedFriendData = snapshot.value as! [String: AnyObject]
                        let first_name: String = selectedFriendData["first_name"] as! String
                        let last_name: String = selectedFriendData["last_name"] as! String
                        self.addFriendBtn.setTitle("\(first_name) \(last_name)", for: UIControlState())
                        
                        // Set local selectedLocation
                        self.selectedFriend = [
                            "id": snapshot.key as AnyObject,
                            "first_name": first_name as AnyObject,
                            "last_name": last_name as AnyObject
                        ]
                    })
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // View is shown again
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    func dismissKeyboard() {
        
        reminderTxt.resignFirstResponder()
        
    }
    
    func closeViewController() {
        
        if isModal() {
            self.dismiss(animated: true, completion: nil)
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    @IBAction func closeBtnAction(_ sender: AnyObject) {
        
        closeViewController()
        
    }
    
    @IBAction func addReminder(_ sender: AnyObject) {
        
        activity.isHidden = false
        activity.startAnimating()
        
        let setFor = (selectedFriend.count > 0 ? selectedFriend["id"] as? String : FIRAuth.auth()?.currentUser?.uid)
        
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        let saveError = UIAlertController(title: "Error", message: "An error occured saving the reminder", preferredStyle: UIAlertControllerStyle.alert)
        saveError.addAction(OKAction)
        
        let locationError = UIAlertController(title: "Error", message: "Please select a location and enter some reminder text.", preferredStyle: UIAlertControllerStyle.alert)
        locationError.addAction(OKAction)
        
        // Validate
        if selectedLocation.count < 1 || reminderTxt.text == "" {
            
            self.present(locationError, animated: true, completion: nil)
        
        } else {
            
            // Save to firebase if editing else if adding new
            if let identifier = reminderIdentifier {
                
                Minders().editReminder(identifier, content: reminderTxt.text, location: selectedLocation, timing: whenSelector.selectedSegmentIndex, setBy: (FIRAuth.auth()?.currentUser?.uid)!, setFor: setFor!, completion: { (returnedMinder, error) -> Void in
                    
                    if !error {
                        Minders().sendReminderNotification(returnedMinder)
                        self.activity.isHidden = true
                        self.activity.stopAnimating()
                        self.closeViewController()
                    } else {
                        self.present(saveError, animated: true, completion: nil)
                    }
                })
                
            } else {
            
                Minders().addReminder(reminderTxt.text, location: selectedLocation, timing: whenSelector.selectedSegmentIndex, setBy: (FIRAuth.auth()?.currentUser?.uid)!, setFor: setFor!, completion: { (returnedMinder, error) -> Void in
                    
                    if !error {
                        Minders().sendReminderNotification(returnedMinder)
                        self.activity.isHidden = true
                        self.activity.stopAnimating()
                        self.closeViewController()
                    } else {
                        self.present(saveError, animated: true, completion: nil)
                    }
                    
                })
                
            }
            
        }
    }
    
    @IBAction func unwindFromLocationSelection(_ segue: UIStoryboardSegue) {
        
        let locationController = segue.source as! AddLocationViewController
        
        if segue.identifier == "LocationUnwindSegue" {
            
            // Set data from location controller
            let nameForLocation = locationController.selectedLocation["name"] as! String == "My current location" ? "Dropped pin" : locationController.selectedLocation["name"] as! String
            locationController.selectedLocation["name"] = nameForLocation as AnyObject?
            
            var name: String = nameForLocation
            if let address: String = locationController.selectedLocation["address"] as? String {
                name += " at \(address)"
            }
            addLocationBtn.setTitle("\(name)", for: UIControlState())
            
            // Set local selectedLocation
            selectedLocation = locationController.selectedLocation
        }
        
    }
    
    @IBAction func unwindFromFriendSelection(_ segue: UIStoryboardSegue) {
        
        let friendController = segue.source as! AddFriendViewController
        
        if segue.identifier == "AddFriendUnwindSegue" {
            
            // Set data from location controller
            var friendForLocation = friendController.selectedFriend
            let first_name: String = friendForLocation!["first_name"]!
            let last_name: String = friendForLocation!["last_name"]!
            addFriendBtn.setTitle("\(first_name) \(last_name)", for: UIControlState())
            
            // Set local selectedLocation
            selectedFriend = friendController.selectedFriend as [String : AnyObject]
        }
        
    }
    
    func isModal() -> Bool {
        if((self.presentingViewController) != nil) {
            return true
        }
        
        if(self.presentingViewController?.presentedViewController == self) {
            return true
        }
        
        if(self.navigationController?.presentingViewController?.presentedViewController == self.navigationController) {
            return true
        }
        
        if((self.tabBarController?.presentingViewController?.isKind(of: UITabBarController.self)) != nil) {
            return true
        }
        
        return false
    }

}
