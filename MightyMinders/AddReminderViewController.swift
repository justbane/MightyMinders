//
//  AddReminderViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 5/6/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class AddReminderViewController: MMCustomViewController {

    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
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
        activity.hidden = true
        if isModal() {
            closeBtn.hidden = false
        }
        
        // Setup swipe down to hide keyboard
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipe.direction = UISwipeGestureRecognizerDirection.Down
        self.view.addGestureRecognizer(swipe)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        // Check for valid user
        if ref.authData == nil {
            super.showLogin()
        } else {
            // If selected friend exits
            if !selectedFriend.isEmpty {
                let first_name: String = selectedFriend["first_name"]! as! String
                let last_name: String = selectedFriend["last_name"]! as! String
                addFriendBtn.setTitle("\(first_name) \(last_name)", forState: .Normal)
            }
            
            // Setup interface values if editing a reminder
            if reminderIdentifier != nil {
                screenTitleLbl.text = "Edit Reminder"
                
                reminderTxt.text = reminderTextFromView
                whenSelector.selectedSegmentIndex = reminderTimingFromView
                selectedLocation = selectedLocationFromView
                
                if let selectedName = selectedLocationFromView["name"] as? String {
                    addLocationBtn.setTitle(selectedName, forState: .Normal)
                }
                
                if let selectedAddress = selectedLocationFromView["address"] as? String {
                    let curText = addLocationBtn.titleForState(.Normal)!
                    addLocationBtn.setTitle("\(curText) at \(selectedAddress)", forState: .Normal)
                }
                
                if !(selectedFriendFromView.isEmpty) && selectedFriendFromView != ref.authData.uid {
                    ref.childByAppendingPath("users/\(selectedFriendFromView)").observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
                        // Set data from location controller
                        
                        let first_name: String = snapshot.value.objectForKey("first_name") as! String
                        let last_name: String = snapshot.value.objectForKey("last_name") as! String
                        self.addFriendBtn.setTitle("\(first_name) \(last_name)", forState: .Normal)
                        
                        // Set local selectedLocation
                        self.selectedFriend = [
                            "id": snapshot.key,
                            "first_name": first_name,
                            "last_name": last_name
                        ]
                    })
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        // View is shown again
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    func dismissKeyboard() {
        
        reminderTxt.resignFirstResponder()
        
    }
    
    func closeViewController() {
        
        if isModal() {
            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            self.navigationController?.popViewControllerAnimated(true)
        }
        
    }
    
    @IBAction func closeBtnAction(sender: AnyObject) {
        
        closeViewController()
        
    }
    
    @IBAction func addReminder(sender: AnyObject) {
        
        activity.hidden = false
        activity.startAnimating()
        
        let setFor = (selectedFriend.count > 0 ? selectedFriend["id"] : ref.authData.uid) as! String
        
        let saveError = UIAlertView(title: "Error", message: "An error occured saving the reminder", delegate: nil, cancelButtonTitle: "OK")
        
        let locationError = UIAlertView(title: "Error", message: "Please select a location and enter some reminder text", delegate: nil, cancelButtonTitle: "OK")
        
        // Validate
        if selectedLocation.count < 1 || reminderTxt.text == "" {
            
            locationError.show()
        
        } else {
            
            // Save to firebase if editing else if adding new
            if let identifier = reminderIdentifier {
                
                Minders().editReminder(identifier, content: reminderTxt.text, location: selectedLocation, timing: whenSelector.selectedSegmentIndex, setBy: ref.authData.uid, setFor: setFor, completion: { (returnedMinder, error) -> Void in
                    
                    if !error {
                        Minders().sendReminderNotification(returnedMinder)
                        self.activity.hidden = true
                        self.activity.stopAnimating()
                        self.closeViewController()
                    } else {
                        saveError.show()
                    }
                })
                
            } else {
            
                Minders().addReminder(reminderTxt.text, location: selectedLocation, timing: whenSelector.selectedSegmentIndex, setBy: ref.authData.uid, setFor: setFor, completion: { (returnedMinder, error) -> Void in
                    
                    if !error {
                        Minders().sendReminderNotification(returnedMinder)
                        self.activity.hidden = true
                        self.activity.stopAnimating()
                        self.closeViewController()
                    } else {
                        saveError.show()
                    }
                    
                })
                
            }
            
        }
    }
    
    @IBAction func unwindFromLocationSelection(segue: UIStoryboardSegue) {
        
        let locationController = segue.sourceViewController as! AddLocationViewController
        
        if segue.identifier == "LocationUnwindSegue" {
            
            // Set data from location controller
            let nameForLocation = locationController.selectedLocation["name"] as! String == "My current location" ? "Dropped pin" : locationController.selectedLocation["name"] as! String
            locationController.selectedLocation["name"] = nameForLocation
            
            var name: String = nameForLocation
            if let address: String = locationController.selectedLocation["address"] as? String {
                name += " at \(address)"
            }
            addLocationBtn.setTitle("\(name)", forState: .Normal)
            
            // Set local selectedLocation
            selectedLocation = locationController.selectedLocation
        }
        
    }
    
    @IBAction func unwindFromFriendSelection(segue: UIStoryboardSegue) {
        
        let friendController = segue.sourceViewController as! AddFriendViewController
        
        if segue.identifier == "AddFriendUnwindSegue" {
            
            // Set data from location controller
            var friendForLocation = friendController.selectedFriend
            let first_name: String = friendForLocation["first_name"]!
            let last_name: String = friendForLocation["last_name"]!
            addFriendBtn.setTitle("\(first_name) \(last_name)", forState: .Normal)
            
            // Set local selectedLocation
            selectedFriend = friendController.selectedFriend
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
        
        if((self.tabBarController?.presentingViewController?.isKindOfClass(UITabBarController)) != nil) {
            return true
        }
        
        return false
    }

}
