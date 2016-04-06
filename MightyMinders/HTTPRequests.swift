//
//  HTTPRequests.swift
//  MightyMinders
//
//  Created by Justin Bane on 10/27/15.
//  Copyright © 2015 Justin Bane. All rights reserved.
//

import Foundation
import Alamofire

struct HTTPRequests {
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    // MARK: Send POST request
    func sendPostRequest(params: [String: [String: AnyObject]], url : String, postCompleted : (success: Bool, msg: Dictionary<String, NSObject>) -> ()) {
        
        let username = userDefaults.valueForKey("restUsername")!
        let password = userDefaults.valueForKey("restPassword")!
        
        let credentialData = "\(username):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64Credentials = credentialData.base64EncodedStringWithOptions([])
        
        let headers = [
            "Authorization": "Basic \(base64Credentials)",
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        // Send the request
        Alamofire.request(.POST, url, parameters: params, encoding: .JSON, headers: headers)
//        debugPrint(request)
            .validate(statusCode: 200..<300)
            .responseJSON { (response) -> Void in
                switch response.result {
                case .Success:
                    postCompleted(success: true, msg: ["status": "\(response)"])
                
                case .Failure:
                    print(response)
                }
        }
        
    }
    
    // End class
}