//
//  Logo.swift
//  MightyMinders
//
//  Created by Justin Bane on 7/25/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import Foundation
import UIKit

class Logo {
    
    let imageView: UIImageView?
    
    init(imgName: String, navController: UINavigationController) {
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 175, height: 35))
        imageView!.contentMode = .ScaleAspectFit
        let image = UIImage(named: imgName)
        imageView!.image = image
        
    }
    
    init(imgName: String, tabController: UITabBarController) {
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 175, height: 35))
        imageView!.contentMode = .ScaleAspectFit
        let image = UIImage(named: imgName)
        imageView!.image = image
    
    }
    
    func getLogoImage() -> UIImageView {
        return self.imageView!
    }
    
    // End class
}