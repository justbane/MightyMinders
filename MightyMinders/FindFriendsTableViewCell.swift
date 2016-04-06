//
//  FindFriendsTableViewCell.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/25/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class FindFriendsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var allowBtn: CustomButton!
    @IBOutlet weak var addBtn: AddRemoveButtonView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // End class
}
