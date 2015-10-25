//
//  TextFields.swift
//  MightyMinders
//
//  Created by Justin Bane on 4/30/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import Foundation
import UIKit

// Class for left margin
class MMTextField : UITextField {
    var leftMargin : CGFloat = 10.0
    
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        var newBounds = bounds
        newBounds.origin.x += leftMargin
        return newBounds
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        var newBounds = bounds
        newBounds.origin.x += leftMargin
        return newBounds
    }
}