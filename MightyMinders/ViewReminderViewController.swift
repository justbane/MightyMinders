//
//  ViewReminderViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 7/11/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class ViewReminderViewController: MMCustomViewController {
    
    let ref = FIRDatabase.database().reference()
    
    var reminderText: String!
    var reminderIdentifier: String!
    var completeReminder: Bool = false
    var timingText: String!
    var selectedFriendFromView: String!
    var setByFromView: String!
    
    @IBOutlet weak var minderLbl: UILabel!
    @IBOutlet weak var completeBtn: UIButton!
    @IBOutlet weak var repeatBtn: UIButton!
    @IBOutlet weak var timingLbl: UILabel!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var setByLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        minderLbl.text = reminderText
        timingLbl.text = timingText
        
        if !(selectedFriendFromView.isEmpty) {
            setByLbl.isHidden = false
            let friendRef = ref.child("users").child(selectedFriendFromView)
            friendRef.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
                // Set data from location controller
                let first_name: String = (snapshot.value! as AnyObject).object(forKey: "first_name") as! String
                let last_name: String = (snapshot.value! as AnyObject).object(forKey: "last_name") as! String
                
                if (FIRAuth.auth()?.currentUser?.uid)! != self.selectedFriendFromView {
                    self.setByLbl.text = "Set for: \(first_name) \(last_name)"
                } else {
                    let setForRef = self.ref.child("users/\(self.setByFromView)")
                    setForRef.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
                        let first_name: String = (snapshot.value! as AnyObject).object(forKey: "first_name") as! String
                        let last_name: String = (snapshot.value! as AnyObject).object(forKey: "last_name") as! String
                        self.setByLbl.text = "Set for you by: \(first_name) \(last_name)"
                    })
                }
                
            })
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Check for valid user
        if FIRAuth.auth()?.currentUser == nil {
            super.showLogin()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeBtnAction(_ sender: AnyObject) {
        completeReminder = false
    }
    
    @IBAction func completeBtnAction(_ sender: AnyObject) {
        completeReminder = true
    }
    
    
    // MARK: Segues
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        self.dismiss(animated: true, completion: nil)
        return true
    }

    /*
    // MARK: Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
