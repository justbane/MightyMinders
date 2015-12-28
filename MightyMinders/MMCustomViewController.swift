//
//  MMCustomViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/22/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class MMCustomViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // logo
        if let navControl = navigationController  {
            navigationItem.titleView = Logo(imgName: "MightyMinders", navController: navControl).getLogoImage()
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showLogin() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") 
        self.presentViewController(vc, animated: true, completion: nil)
        
    }
}
