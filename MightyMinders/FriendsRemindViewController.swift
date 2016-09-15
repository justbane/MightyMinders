//
//  FriendsRemindViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/22/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class FriendsRemindViewController: MMCustomViewController, UITableViewDelegate, UITableViewDataSource {

    let ref = FIRDatabase.database().reference()
    let userDefaults = UserDefaults.standard
    var friendData: [FIRDataSnapshot?] = []
    var friendKeys: [String] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var friendsActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // Table view setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsets.zero
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Show the activity
        friendsActivity.startAnimating()
        friendsActivity.isHidden = false
        
        if FIRAuth.auth()?.currentUser == nil {
            super.showLogin()
        } else {
            // Get the friend keys
            Friends().getFriendKeysThatRemindMe({ (friendsRemindMe) -> Void in
                // Set object
                let enumerator = friendsRemindMe.children
                
                // Reset arrays - reset the table
                self.friendKeys.removeAll(keepingCapacity: false)
                self.friendData.removeAll(keepingCapacity: false)
                self.tableView.reloadData()
                
                // Iterate over data
                while let data = enumerator.nextObject() as? FIRDataSnapshot {
                    self.friendKeys.append(data.key)
                }
                // Get friends
                self.getFriends()
                
                // Hide the activity
                self.friendsActivity.stopAnimating()
                self.friendsActivity.isHidden = true
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getFriends() {
        
        if friendKeys.count > 0 {
            // Loop over friend IDs
            for uid in friendKeys {
                Friends().getFriends(uid, completion: { (friendsData) -> Void in
                    self.friendData.append(friendsData)
                    if self.friendData.count > 0 {
                        // Reload the table
                        self.tableView.reloadData()
                    }
                })
            }
            
        }
        
    }
    
    @IBAction func removeBtnAction(_ sender: CustomButton) {
        
        if (sender.actionData != nil) {
            
            // Remove from my allowed list
            Friends().removeFriendAccess(sender.actionData)
            
            // Remove from their can remind list
            Friends().removeMeFromCanRemindList(sender.actionData)
            
        }
        
    }
    
    // MARK: TableView requirements
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendData.count
    }
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "canRemindMeCell") as! FindFriendsTableViewCell
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        // Cell button setup
        cell.allowBtn.actionData = friendData[(indexPath as NSIndexPath).row]?.key
        cell.allowBtn.addTarget(self, action: #selector(removeBtnAction), for: .touchUpInside)
        
        var name : String = ""
        
        if let firstName = (friendData[(indexPath as NSIndexPath).row]?.value! as AnyObject).value(forKey: "first_name") as? NSString {
            name += firstName as String
        }
        
        if let lastName = (friendData[(indexPath as NSIndexPath).row]?.value! as AnyObject).value(forKey: "last_name") as? NSString {
            name += " \(lastName)"
        }
        
        (cell.contentView.viewWithTag(101) as! UILabel).text = name
        
        if let email = (friendData[(indexPath as NSIndexPath).row]?.value! as AnyObject).value(forKey: "email_address") as? NSString {
            (cell.contentView.viewWithTag(102) as! UILabel).text = email as String
        }
        
        // TODO - add profile images 
//        if var imageURL = contacts[indexPath.row].valueForKey("profile_img") as? NSString {
//            
//            if imageURL == "" {
//                imageURL = "/images/NoAvatar.gif"
//            }
//            
//            let urlString: NSString = "http:/internal.hdmz.com\(imageURL)"
//            let imgURL: NSURL? = NSURL(string: urlString as String)
//            
//            let request: NSURLRequest = NSURLRequest(URL: imgURL!)
//            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
//                
//                if error == nil {
//                    
//                    dispatch_async(dispatch_get_main_queue(), {
//                        if let cellToUpdate = self.tblView.cellForRowAtIndexPath(indexPath) {
//                            var imageToUpdate = Images().roundCorners(cellToUpdate.contentView.viewWithTag(100) as! UIImageView, radiusSize: 22.5)
//                            imageToUpdate.image = UIImage(data: data)
//                            self.imageCache[imageURL as String] = UIImage(data: data)
//                        }
//                    })
//                    
//                }
//                
//            })
//            
//        }
        
        // Return the cell with data
        return cell
    }
    
}
