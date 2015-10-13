//
//  ProfileViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/9/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    
    
    @IBOutlet var logoutBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logoutAction(sender: UIButton) {
        
        // kill firebase session
        ref.unauth()
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    

}
