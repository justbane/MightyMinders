//
//  AddRemoveButton.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/15/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

@IBDesignable class AddRemoveButtonView: UIButton {
    
    var actionData: [String: String]!
    var locationData: [String: Double]!
    
    @IBInspectable var plusButton: Bool = true
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    
    override func draw(_ rect: CGRect) {
        
        let path = UIBezierPath(ovalIn: rect)
        
        if plusButton {
            UIColor(red: 52/255.0, green: 186/255.0, blue: 158/255.0, alpha: 1.0).setFill()
        } else {
            UIColor(red: 180/255.0, green: 40/255.0, blue: 28/255.0, alpha: 1.0).setFill()
        }
        path.fill()
        
        let plusHeight: CGFloat = 3.0
        let plusWidth: CGFloat = min(bounds.width, bounds.height) * 0.6
        
        // Create the path
        let plusPath = UIBezierPath()
        
        // Set the path's line width to the height of the stroke
        plusPath.lineWidth = plusHeight
        
        // Horizontal line
        // Move inital point of path to start of stroke
        // then add point to path at end of stroke
        plusPath.move(to: CGPoint(x: bounds.width/2 - plusWidth/2 + 0.5, y: bounds.height/2 + 0.5))
        plusPath.addLine(to: CGPoint(x: bounds.width/2 + plusWidth/2 + 0.5, y: bounds.height/2 + 0.5))
        
        // Vertical Line
        if plusButton {
            plusPath.move(to: CGPoint(x: bounds.width/2 + 0.5, y: bounds.height/2 - plusWidth/2 + 0.5))
            plusPath.addLine(to: CGPoint(x: bounds.width/2 + 0.5, y: bounds.height/2 + plusWidth/2 + 0.5))
        }
        
        
        // Draw :)
        UIColor.white.setStroke()
        plusPath.stroke()
        
    }
    
    // End Class
}
