//
//  FindFriendsViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/12/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class FindFriendsViewController: MMCustomViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    let ref = FIRDatabase.database().reference()
    
    var searchActive: Bool = false;
    var friendData: [FIRDataSnapshot?] = []
    var searchDataCount: Int = 0
    var currentFriends = Set<String>()
    
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Table view setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsets.zero
        
        // Setup searchbar
        searchBar.delegate = self
        searchBar.keyboardAppearance = UIKeyboardAppearance.dark
        searchBar.autocapitalizationType = UITextAutocapitalizationType.none
        
        // Get current friends
        Friends().getFriendKeysThatRemindMe { (friendsRemindMe) -> Void in
            let enumerator = friendsRemindMe.children
            while let data = enumerator.nextObject() as? FIRDataSnapshot {
                //print(data.key)
                self.currentFriends.insert(data.key)
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Check for valid user
        
        // Hide the activity
        self.searchActivity.isHidden = true
        
        if FIRAuth.auth()?.currentUser == nil {
            super.showLogin()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    @IBAction func closeBtnAction(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func allowBtnAction(_ sender: CustomButton) {
        
        var errors = false
        
        if (sender.actionData != nil) {
            
            // Add to my allowed list
            Friends().addAllowedFriends(sender.actionData, completion: { (error) -> Void in
                if error {
                    errors = true
                }
            })
            
            // Add to their can remind list
            Friends().addToCanRemindFriends(sender.actionData, completion: { (error) -> Void in
                if error {
                    errors = true
                }
            })
            
            if !errors {
                self.dismiss(animated: true, completion: nil)
            } else {
                let saveError = UIAlertController(title: "Error", message: "An error occured saving the data", preferredStyle: UIAlertControllerStyle.alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                saveError.addAction(OKAction)
                self.present(saveError, animated: true, completion: nil)
            }
        }
        
    }
    
    // MARK: Searchbar requirements
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText != "" && searchText.characters.count >= 2 && searchText.contains("@") {
            
            // Show activity
            searchActivity.startAnimating()
            searchActivity.isHidden = false
            
            // Search users by email
            Friends().searchFriendsByEmail(searchText, completion: { (usersFound) -> Void in
                if (usersFound.value! as AnyObject).count != nil {
                    
                    // Remove data from array and reset count
                    self.friendData.removeAll(keepingCapacity: false)
                    self.searchDataCount = 0
                    
                    // Iterate the results and add to array
                    let enumerator = usersFound.children
                    while let data = enumerator.nextObject() as? FIRDataSnapshot {
                        if data.key != (FIRAuth.auth()?.currentUser?.uid)! && !self.currentFriends.contains(data.key) {
                            self.friendData.append(data)
                        }
                        //print(data);
                    }
                    
                    // Update table
                    if self.friendData.count > 0 {
                        // Set row count and reload
                        self.searchDataCount = self.friendData.count
                        self.tableView.reloadData()
                    }
                    
                }
                
                // Hide the activity
                self.searchActivity.stopAnimating()
                self.searchActivity.isHidden = true
            })
            
        }
        
    }

    // MARK: TableView requirements
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchDataCount
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendsTableCell") as! FindFriendsTableViewCell
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        let cellData = friendData[indexPath.row]?.value as! [String: AnyObject]
        
        // Cell button setup
        cell.allowBtn.actionData = (friendData[indexPath.row]?.key)!
        cell.allowBtn.addTarget(self, action: #selector(allowBtnAction), for: .touchUpInside)
        
        var name: String = ""
        
        if let firstName = cellData["first_name"] {
            name += "\(firstName)"
        }
        
        if let lastName = cellData["last_name"] {
            name += " \(lastName)"
        }
        
        (cell.contentView.viewWithTag(101) as! UILabel).text = name
        
        if let email = cellData["email_address"] as? String {
            (cell.contentView.viewWithTag(102) as! UILabel).text = email
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
