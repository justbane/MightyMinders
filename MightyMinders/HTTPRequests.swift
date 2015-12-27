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
    
    init() {}
    
    func sendPostRequest(params: [String: [String: AnyObject]], url : String, postCompleted : (success: Bool, msg: Dictionary<String, NSObject>) -> ()) {
        
        // REST credentials - prod
        let username = "1ce88109-d9f0-447e-b990-5b65240d8a73"
        let password = "8f9b189d-f55e-4cd0-b417-19f0136d440a"
        
        // REST credentials - dev
        // let username = "f8de81a1-ce56-496e-8e6d-f179244b7450"
        // let password = "e37fb59b-0895-4d85-9d34-6d8a2b3cce86"
        
        let credentialData = "\(username):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64Credentials = credentialData.base64EncodedStringWithOptions([])
        
        let headers = [
            "Authorization": "Basic \(base64Credentials)",
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        // send the request
        Alamofire.request(.POST, url, parameters: params, encoding: .JSON, headers: headers)
//        debugPrint(request)
            .validate(statusCode: 200..<300)
            .responseJSON { (response) -> Void in
                postCompleted(success: true, msg: ["status": "\(response)"])
        }
        
    }
    
}