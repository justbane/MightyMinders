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
    var selectedLocation = [String: AnyObject]()
    var selectedFriend = [String: AnyObject]()
    
    // values from view if editing
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Setup interface values if editing a reminder -- FIXME!
        if let _ = reminderIdentifier {
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
                let friendRef = ref.childByAppendingPath("users/\(selectedFriendFromView)")
                friendRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
                    // set data from location controller
                    
                    let first_name: String = snapshot.value.objectForKey("first_name") as! String
                    let last_name: String = snapshot.value.objectForKey("last_name") as! String
                    self.addFriendBtn.setTitle("\(first_name) \(last_name)", forState: .Normal)
                    
                    // set local selectedLocation
                    self.selectedFriend = [
                        "id": snapshot.key,
                        "first_name": first_name,
                        "last_name": last_name
                    ]
                })
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        
        // view is shown again
        // println("Updates viewDidAppear fired")
        
        if ref.authData != nil {
            // user authenticated with Firebase
        } else {
            super.showLogin()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    @IBAction func addReminder(sender: AnyObject) {
        
        let userMinder = [
            "content": reminderTxt.text,
            "location": selectedLocation,
            "timing": whenSelector.selectedSegmentIndex,
            "set-by": ref.authData.uid as String,
            "set-for": (selectedFriend.count > 0 ? selectedFriend["id"] : ref.authData.uid) as! String
        ]
        
        // set the ref path
        var usersMindersRef = ref.childByAppendingPath("minders/\(ref.authData.uid)/private")
        
        // are we editing?
        if let identifier = reminderIdentifier {
            usersMindersRef = ref.childByAppendingPath("minders/\(ref.authData.uid)/private/\(identifier)")
        }
        
        // is there a friend selected?
        if selectedFriend.count > 0 {
            usersMindersRef = ref.childByAppendingPath("shared-minders")
            
            // is there a friend and we are editing?
            if let identifier = reminderIdentifier {
                usersMindersRef = ref.childByAppendingPath("shared-minders/\(identifier)")
            }
        
        }
        
        // validate
        if selectedLocation.count < 1 || reminderTxt.text == "" {
            
            //check for the location
            let locationError = UIAlertView(title: "Error", message: "Please select a location and enter some reminder text", delegate: nil, cancelButtonTitle: "OK")
            locationError.show()
        
        } else {
            
            // save to firebase if editing else if adding new
            if let identifier = reminderIdentifier {
                usersMindersRef.updateChildValues(userMinder as [NSObject : AnyObject], withCompletionBlock: { (error:NSError?, ref:Firebase!) in
                    if error != nil {
                        let saveError = UIAlertView(title: "Error", message: "An error occured saving the reminder", delegate: nil, cancelButtonTitle: "OK")
                        saveError.show()
                    } else {
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                })
                
                // remove minder from private if adding a friend
                if (self.selectedFriend.count > 0 && selectedFriend["id"] as! String != ref.authData.uid as String) {
                    let usersMinderRemove = ref.childByAppendingPath("minders/\(ref.authData.uid)/private/\(identifier)")
                    usersMinderRemove.removeValue()
                }
                
            } else {
                let usersMindersRefAuto = usersMindersRef.childByAutoId()
                usersMindersRefAuto.setValue(userMinder, withCompletionBlock: { (error:NSError?, ref:Firebase!) in
                    if error != nil {
                        let saveError = UIAlertView(title: "Error", message: "An error occured saving the reminder", delegate: nil, cancelButtonTitle: "OK")
                        saveError.show()
                    } else {
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                })
                
            }
            
        }
    }
    
    @IBAction func unwindFromLocationSelection(segue: UIStoryboardSegue) {
        
        let locationController = segue.sourceViewController as! AddLocationViewController
        
        if segue.identifier == "LocationUnwindSegue" {
            
            // set data from location controller
            let nameForLocation = locationController.selectedLocation["name"]! as! String == "My current location" ? "Dropped pin" : locationController.selectedLocation["name"]! as! String
            
            let name: String = nameForLocation
            let address: String = locationController.selectedLocation["address"]! as! String
            addLocationBtn.setTitle("\(name) at \(address)", forState: .Normal)
            
            // set local selectedLocation
            selectedLocation = locationController.selectedLocation
        }
        
    }
    
    @IBAction func unwindFromFriendSelection(segue: UIStoryboardSegue) {
        
        let friendController = segue.sourceViewController as! AddFriendViewController
        
        if segue.identifier == "AddFriendUnwindSegue" {
            
            // set data from location controller
            var friendForLocation = friendController.selectedFriend
            let first_name: String = friendForLocation["first_name"]!
            let last_name: String = friendForLocation["last_name"]!
            addFriendBtn.setTitle("\(first_name) \(last_name)", forState: .Normal)
            
            // set local selectedLocation
            selectedFriend = friendController.selectedFriend
        }
        
    }

}
