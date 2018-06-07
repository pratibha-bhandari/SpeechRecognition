//
//  Activity.swift
//  SpeechRecognition
//
//  Created by Admin on 07/06/18.
//  Copyright © 2018 DB. All rights reserved.
//

import UIKit

class Activity: NSObject {
    public var type : String?
    public var id : String?
    public var timestamp : String?
    public var serviceUrl : String?
    public var channelId : String?
    public var from: Dictionary<String, Any>?
    public var conversation: Dictionary<String, Any>?
    public var text : String?
    
    required public init?(dictionary: NSDictionary) {
        
        type = dictionary["type"] as? String
        id = dictionary["id"] as? String
        timestamp = dictionary["timestamp"] as? String
        serviceUrl = dictionary["serviceUrl"] as? String
        channelId = dictionary["channelId"] as? String
        if (dictionary["from"] != nil) {
            from = dictionary["from"] as? Dictionary<String, Any>
        }
        if (dictionary["conversation"] != nil) {
            conversation = dictionary["conversation"] as? Dictionary<String, Any>
        }
        if dictionary["text"] as? String == "" {
            
            let attachmentsArray = dictionary.object(forKey:"attachments") as! NSArray
            let attachmentDict = attachmentsArray.firstObject as! NSDictionary
            let contentDict = attachmentDict["content"] as! NSDictionary
            text = contentDict["text"] as? String
            
        } else {
            text = dictionary["text"] as? String
        }
    }
}
