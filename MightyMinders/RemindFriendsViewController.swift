//
//  RemindFriendsViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/9/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class RemindFriendsViewController: MMCustomViewController, UITableViewDelegate, UITableViewDataSource {

    let ref = FIRDatabase.database().reference()
    let userDefaults = UserDefaults.standard
    var friendData: [FIRDataSnapshot?] = []
    var friendKeys: [String] = []
    var selectedFriend: [String: String]!
    
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
        
        // Friends activity
        friendsActivity.startAnimating()
        friendsActivity.isHidden = false
        
        if FIRAuth.auth()?.currentUser == nil {
            super.showLogin()
        } else {
            // Get friends keys
            Friends().getFriendKeysICanRemind({ (friendsToRemind) -> Void in
                // Set object
                let enumerator = friendsToRemind.children
                
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
                
                // Hide activity
                self.friendsActivity.stopAnimating()
                self.friendsActivity.isHidden = true
            })

        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Get friends
    func getFriends() {
        
        // Add to friends list
        if friendKeys.count > 0 {
            // Loop over firend IDs
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
    
    // MARK: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SelectedFriendSegue" {
            let addReminderViewController = segue.destination as! AddReminderViewController
            if let sendingBtn = sender as? AddRemoveButtonView {
                addReminderViewController.selectedFriend = sendingBtn.actionData as [String : AnyObject]
            }
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "iCanRemindCell") as! FindFriendsTableViewCell
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        // Cell button setup
        cell.addBtn.actionData = [
            "id": friendData[(indexPath as NSIndexPath).row]!.key,
            "first_name": (friendData[(indexPath as NSIndexPath).row]!.value! as AnyObject).value(forKey: "first_name") as! String,
            "last_name": (friendData[(indexPath as NSIndexPath).row]?.value! as AnyObject).value(forKey: "last_name") as! String
        ]
        
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
        
        // TODO: Add profile images
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
