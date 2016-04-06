//
//  CustomView.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/8/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

@IBDesignable public class CustomView: UIView {
    
    override public class func layerClass()->AnyClass{
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
    
    @IBInspectable var startColor: UIColor = UIColor.clearColor() {
        didSet {
            updateUI()
        }
    }
    
    @IBInspectable var endColor: UIColor = UIColor.clearColor() {
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
    
    @IBInspectable var borderColor: UIColor = UIColor.clearColor() {
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
        
        layer.borderColor = borderColor.CGColor
        layer.borderWidth = borderWidth
        
        let colors:Array = [startColor.CGColor, endColor.CGColor]
        gradientLayer.colors = colors
        gradientLayer.cornerRadius = roundness
        gradientLayer.startPoint = CGPointZero;
        if isHorizontal {
            gradientLayer.endPoint = CGPointMake(1, 1);
        } else {
            gradientLayer.endPoint = CGPointMake(0, 1);
        }
        
        self.setNeedsDisplay()
        
    }
    
    // Helper to return the main layer as CAGradientLayer
    var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    
    // End class
}
