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
    func sendPostRequest(params: [String: AnyObject], postCompleted : (success: Bool, msg: Dictionary<String, NSObject>) -> ()) {
        
        let remoteConfig = FIRRemoteConfig.remoteConfig()
        
        remoteConfig.fetchWithCompletionHandler { (status, error) in
            if (status == FIRRemoteConfigFetchStatus.Success) {
                
                // print("Config fetched!")
                remoteConfig.activateFetched()
                
                let key = remoteConfig.configValueForKey("fcm_key").stringValue!
                let url = "https://fcm.googleapis.com/fcm/send"
                let headers = [
                    "Authorization": "key=\(key)",
                    "Content-Type": "application/json",
                ]
                
                var paramData: [String: AnyObject] = [
                    "to": params["to"]!,
                    "notification": [
                        "title": params["notification"]!["title"],
                        "body": params["notification"]!["body"],
                        "sound": "default",
                        "click_action": "MAIN_CATEGORY"
                    ]
                ]
                
                if params["data"] != nil {
                    paramData["data"] = params["data"]
                }
                
                // Send the request
                // let request =
                Alamofire.request(.POST, url, parameters: paramData, encoding: .JSON, headers: headers)
                    .validate(statusCode: 200..<300)
                    .responseJSON { (response) -> Void in
                        switch response.result {
                        case .Success:
                            postCompleted(success: true, msg: ["status": "\(response)"])
                            
                        case .Failure:
                            print(response)
                        }
                }
                
                // debugPrint(request)
                
            } else {
                print("Config not fetched")
                print("Error \(error!.localizedDescription)")
            }
        }
        
    }
    
    // End class
}