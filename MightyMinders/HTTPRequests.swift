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
    
    let userDefaults = UserDefaults.standard
    
    // MARK: Send POST request
    func sendPostRequest(_ params: [String: AnyObject], postCompleted : @escaping (_ success: Bool, _ msg: Dictionary<String, NSObject>) -> ()) {
        
        let remoteConfig = FIRRemoteConfig.remoteConfig()
        
        remoteConfig.fetch { (status, error) in
            if (status == FIRRemoteConfigFetchStatus.success) {
                
                // print("Config fetched!")
                remoteConfig.activateFetched()
                
                let key = remoteConfig.configValue(forKey: "fcm_key").stringValue!
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
                Alamofire.request(.POST, url, parameters: paramData, encoding: .json, headers: headers)
                    .validate(statusCode: 200..<300)
                    .responseJSON { (response) -> Void in
                        switch response.result {
                        case .success:
                            postCompleted(success: true, msg: ["status": "\(response)"])
                            
                        case .failure:
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
