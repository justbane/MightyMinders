//
//  Colors.swift
//  MightyMinders
//
//  Created by Justin Bane on 4/29/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import Foundation
import UIKit

struct Colors {
    
    let blueColor: UIColor
    let darkblueColor: UIColor
    let orangeColor: UIColor
    let darkorangeColor: UIColor
    let yellowColor: UIColor
    let darkyellowColor: UIColor
    
    var colorGrad: CAGradientLayer
    
    init(colorString: String) {
        
        blueColor = UIColor(red: 27/255.0, green: 109/255.0, blue: 172/255.0, alpha: 1.0)
        darkblueColor = UIColor(red: 36/255.0, green: 55/255.0, blue: 75/255.0, alpha: 1.0)
        
        orangeColor = UIColor(red: 235/255.0, green: 156/255.0, blue: 45/255.0, alpha: 1.0)
        darkorangeColor = UIColor(red: 255/255.0, green: 107/255.0, blue: 21/255.0, alpha: 1.0)
        
        yellowColor = UIColor(red: 239/255.0, green: 196/255.0, blue: 45/255.0, alpha: 1.0)
        darkyellowColor = UIColor(red: 235/255.0, green: 156/255.0, blue: 45/255.0, alpha: 1.0)
        
        colorGrad = CAGradientLayer()
        
        switch(colorString) {
        
        case "blue":
            colorGrad = getGradientLayer(blueColor, bottomColor: darkblueColor)
            
        case "orange":
            colorGrad = getGradientLayer(orangeColor, bottomColor: darkorangeColor)
            
        case "yellow":
            colorGrad = getGradientLayer(yellowColor, bottomColor: darkyellowColor)
            
        default:
            colorGrad = getGradientLayer(blueColor, bottomColor: darkblueColor)
            
        }
        
    }
    
    
    func getGradientLayer(_ topColor: UIColor, bottomColor: UIColor) -> CAGradientLayer {
        
        
        let gradientColors: [AnyObject] = [topColor.cgColor, bottomColor.cgColor]
        let gradientLocations: [NSNumber] = [0.0, 1.0]
        
        let gradientLayer: CAGradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientColors
        gradientLayer.locations = gradientLocations
        
        return gradientLayer
        
    }
    
    func getGradient() -> CAGradientLayer {
        
        return colorGrad
        
    }
    
    // End class
}
