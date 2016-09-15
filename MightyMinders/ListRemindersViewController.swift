//
//  ListRemindersViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 11/10/15.
//  Copyright © 2015 Justin Bane. All rights reserved.
//

import UIKit

class ListRemindersViewController: MMCustomViewController, UITableViewDelegate, UITableViewDataSource {

    let ref = FIRDatabase.database().reference()
    let userDefaults = UserDefaults.standard
    var reminderData: [FIRDataSnapshot?] = []
    var theirReminderData: [FIRDataSnapshot?] = []
    var reminderKeys = Set<String>()
    var selectedReminder: [String: Double]!
    let sectionsInTable = ["Set For You", "Set for Friends"]
    
    // Table row heights
    var selectedCellIndexPath: IndexPath?
    let selectedCellHeight: CGFloat = 180.0
    let unselectedCellHeight: CGFloat = 90.0
    
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // Table view setup
        tableView.delegate = self
        tableView.dataSource = self
        //tableView.separatorInset = UIEdgeInsetsZero
        
        self.getReminders()
        
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
    
    // MARK: Get the reminders
    func getReminders() {
        
        // Private reminders
        Minders().getPrivateMinders { (privateReminders) -> Void in
            let enumerator = privateReminders.children
            while let data = enumerator.nextObject() as? FIRDataSnapshot {
                //print(data.key)
                if !self.reminderKeys.contains(data.key) {
                    self.reminderKeys.insert(data.key)
                    self.reminderData.append(data)
                }
            }
            self.tableView.reloadData()
        }
        
        // Shared minders
        Minders().getSharedReminders { (sharedReminders) -> Void in
            let enumerator = sharedReminders.children
            while let data = enumerator.nextObject() as? FIRDataSnapshot {
                //print(data.key)
                if !self.reminderKeys.contains(data.key) {
                    self.reminderKeys.insert(data.key)
                    self.reminderData.append(data)
                }
            }
            self.tableView.reloadData()
        }
        
        // Set by you        
        Minders().getRemindersSetByYou { (remindersSetByYou) -> Void in
            let enumerator = remindersSetByYou.children
            while let data = enumerator.nextObject() as? FIRDataSnapshot {
                //print(data.key)
                if !self.reminderKeys.contains(data.key) {
                    self.reminderKeys.insert(data.key)
                    self.theirReminderData.append(data)
                }
            }
            self.tableView.reloadData()
        }
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        // Check to see if segue should happen (have they selected a reminder?
        if identifier == "ListViewUnwindSegue" {
            if let sendingBtn = sender as? CustomButton {
                selectedReminder = sendingBtn.locationData
            }
        }
        
        return true
    }
    
    @IBAction func selectReminderAction(_ sender: AddRemoveButtonView) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func closeBtnAction(_ sender: AnyObject) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    func getSectionItems(_ section: Int) -> Int {
        
        var count = 0
        
        if section == 0 {
            count = reminderData.count
        }
        
        if section == 1 {
            count = theirReminderData.count
        }
        
        return count
        
    }
    
    // MARK: TableView requirements
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionsInTable.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getSectionItems(section)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //if selectedCellIndexPath == indexPath {
        //    return selectedCellHeight
        //}
        return unselectedCellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedCellIndexPath != nil && selectedCellIndexPath == indexPath {
            selectedCellIndexPath = nil
        } else {
            selectedCellIndexPath = indexPath
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
        
        if selectedCellIndexPath != nil {
            // This ensures, that the cell is fully visible once expanded
            tableView.scrollToRow(at: indexPath, at: .none, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionsInTable[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "remindersTableCell") as! ListViewTableViewCell
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        if reminderData.count > 0 && (indexPath as NSIndexPath).section == 0 {
            let reminders = (reminderData[(indexPath as NSIndexPath).row]?.value! as AnyObject).value(forKey: "location")
            if let location = reminders {
                cell.viewBtn.locationData = [
                    "latitude": ((location as AnyObject).value(forKey: "latitude") as? Double)!,
                    "longitude": ((location as AnyObject).value(forKey: "longitude") as? Double)!
                ]
                
                if let name = (location as AnyObject).value(forKey: "name") as? NSString {
                    (cell.contentView.viewWithTag(101) as! UILabel).text = name as String
                }
                
                if let address = (location as AnyObject).value(forKey: "address") as? NSString {
                    (cell.contentView.viewWithTag(102) as! UILabel).text = address as String
                }
                
            }
        }
        
        if theirReminderData.count > 0 && (indexPath as NSIndexPath).section == 1 {
            let reminders = (theirReminderData[(indexPath as NSIndexPath).row]?.value! as AnyObject).value(forKey: "location")
            if let location = reminders {
                cell.viewBtn.locationData = [
                    "latitude": ((location as AnyObject).value(forKey: "latitude") as? Double)!,
                    "longitude": ((location as AnyObject).value(forKey: "longitude") as? Double)!
                ]
                
                if let name = (location as AnyObject).value(forKey: "name") as? NSString {
                    (cell.contentView.viewWithTag(101) as! UILabel).text = name as String
                }
                
                if let address = (location as AnyObject).value(forKey: "address") as? NSString {
                    (cell.contentView.viewWithTag(102) as! UILabel).text = address as String
                }

            }
        }
        
        // Cell button setup
        cell.viewBtn.addTarget(self, action: #selector(selectReminderAction), for: .touchUpInside)
        
        // Return the cell with data
        return cell
    }

}
