//
//  ListViewTableViewCell.swift
//  MightyMinders
//
//  Created by Justin Bane on 11/10/15.
//  Copyright © 2015 Justin Bane. All rights reserved.
//

import UIKit

class ListViewTableViewCell: UITableViewCell {
    
    @IBOutlet weak var viewBtn: CustomButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
