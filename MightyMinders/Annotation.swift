//
//  Annotation.swift
//  MightyMinders
//
//  Created by Justin Bane on 6/22/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import Foundation
import MapKit

class Annotation : NSObject, MKAnnotation {
    
    let key: String
    let title: String?
    let subtitle: String?
    let content: String
    let type: String
    let event: Int
    let coordinate: CLLocationCoordinate2D
    let setFor: String
    let setBy: String
    
    init(key: String, title: String, subtitle: String, content: String, type: String, event: Int, coordinate: CLLocationCoordinate2D, setFor: String, setBy: String) {
        self.key = key
        self.title = title
        self.content = content
        self.subtitle = "\(subtitle)"
        self.type = type
        self.event = event
        self.coordinate = coordinate
        self.setFor = setFor
        self.setBy = setBy
        
        super.init()
    }
    
    func pinColor() -> UIColor {
        switch type {
        case "private":
            return .green
        case "shared":
            return .red
        default:
            return .purple
        }
    }
    
    func pinImage() -> UIImage  {
        switch type {
        case "private":
            return UIImage(named: "flag-green.png")!
        case "shared":
            return UIImage(named: "flag-blue.png")!
        default:
            return UIImage(named: "flag-red.png")!
        }
    }
    
}
