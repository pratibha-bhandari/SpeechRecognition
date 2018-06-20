//
//  Activity.swift
//  SpeechRecognition
//
//  Created by Admin on 07/06/18.
//  Copyright © 2018 DB. All rights reserved.
//

import UIKit

class Activity: NSObject, NSCoding {
    
    
    public var type : String?
    public var id : String?
    public var timestamp : String?
    public var serviceUrl : String?
    public var channelId : String?
    public var from: Dictionary<String, Any>?
    public var conversation: Dictionary<String, Any>?
    public var text : String?
    
    init (type : String, id : String, timestamp : String, serviceUrl : String, channelId : String, from : Dictionary<String, Any>, conversation : Dictionary<String, Any>, text : String) {
        self.type = type
        self.id = id
        self.timestamp = timestamp
        self.serviceUrl = serviceUrl
        self.channelId = channelId
        self.from = from
        self.conversation = conversation
        self.text = text
    }
//        public init?(dictionary: NSDictionary?) {
//            if (dictionary != nil) {
//                type = dictionary!["type"] as? String
//                id = dictionary!["id"] as? String
//                timestamp = dictionary!["timestamp"] as? String
//                serviceUrl = dictionary!["serviceUrl"] as? String
//                channelId = dictionary!["channelId"] as? String
//                if (dictionary!["from"] != nil) {
//                    from = dictionary!["from"] as? Dictionary<String, Any>
//                }
//                if (dictionary!["conversation"] != nil) {
//                    conversation = dictionary!["conversation"] as? Dictionary<String, Any>
//                }
//                if dictionary!["text"] as? String == "" {
//
//                    let attachmentsArray = dictionary!.object(forKey:"attachments") as! NSArray
//                    let attachmentDict = attachmentsArray.firstObject as! NSDictionary
//                    let contentDict = attachmentDict["content"] as! NSDictionary
//                    text = contentDict["text"] as? String
//
//                } else {
//                    text = dictionary!["text"] as? String
//                }
//            }
//        }
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.type, forKey: "type")
        aCoder.encode(self.id, forKey: "id")
        aCoder.encode(self.timestamp, forKey: "timestamp")
        aCoder.encode(self.serviceUrl, forKey: "serviceUrl")
        aCoder.encode(self.from, forKey: "from")
        aCoder.encode(self.conversation, forKey: "conversation")
        aCoder.encode(self.channelId, forKey: "channelId")
        aCoder.encode(self.text, forKey: "text")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard let type = aDecoder.decodeObject(forKey: "type") as? String,
            let id = aDecoder.decodeObject(forKey:"id") as? String,
            let timestamp = aDecoder.decodeObject(forKey:"timestamp") as? String,
            let serviceUrl = aDecoder.decodeObject(forKey:"serviceUrl") as? String,
            let from = aDecoder.decodeObject(forKey:"from") as? Dictionary<String, Any>,
            let conversation = aDecoder.decodeObject(forKey:"conversation") as? Dictionary<String, Any>,
            let channelId = aDecoder.decodeObject(forKey:"channelId") as? String,
            let text = aDecoder.decodeObject(forKey:"text") as? String
            else { return nil }
        self.type = type
        self.id = id
        self.timestamp = timestamp
        self.serviceUrl = serviceUrl
        self.from = from
        self.conversation = conversation
        self.channelId = channelId
        self.text = text
    }
}
