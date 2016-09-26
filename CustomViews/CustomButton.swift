//
//  CustomButton.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/8/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

@IBDesignable class CustomButton: UIButton {
    
    var actionData: String!
    var locationData: [String: Double]!
    
    override class var layerClass:AnyClass{
        return CAGradientLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        updateUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        updateUI()
    }
    
    @IBInspectable var startColor: UIColor = UIColor.clear {
        didSet {
            updateUI()
        }
    }
    
    @IBInspectable var endColor: UIColor = UIColor.clear {
        didSet {
            updateUI()
        }
    }
    
    @IBInspectable var isHorizontal: Bool = false {
        didSet{
            updateUI()
        }
    }
    
    @IBInspectable var roundness: CGFloat = 0.0 {
        didSet{
            updateUI()
        }
    }
    
    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet {
            updateUI()
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            updateUI()
        }
    }
    
    func updateUI(){
        
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
        
        let colors:Array = [startColor.cgColor, endColor.cgColor]
        gradientLayer.colors = colors
        gradientLayer.cornerRadius = roundness
        gradientLayer.startPoint = CGPoint.zero;
        if isHorizontal {
            gradientLayer.endPoint = CGPoint(x: 1, y: 1);
        } else {
            gradientLayer.endPoint = CGPoint(x: 0, y: 1);
        }
        
        self.setNeedsDisplay()
        
    }
    
    // Helper to return the main layer as CAGradientLayer
    var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    
    // End class
}
