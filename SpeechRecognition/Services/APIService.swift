//
//  Service.swift
//  SpeechRecognition
//
//  Created by HIMANSHU on 6/5/18.
//  Copyright © 2018 DB. All rights reserved.
//

import Foundation
import UIKit

typealias CompletionHandler = (_ response:NSDictionary) -> Void

class APIService: NSObject
{
    
    // Method to get conversation id from server
    func getConversationIdFromService(completionHandler :@escaping CompletionHandler)
    {
        //Request for getting conversation id
        let url = URL(string:API.baseURL)!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(API.token, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for networking error
                print("error=\(String(describing: error))")
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
                //let appDelegate = UIApplication.shared.delegate as! AppDelegate
                //appDelegate.user?.conversationID = "7BDMBKhbXACBznzJjnMOWp"
                //7BDMBKhbXACBznzJjnMOWp
            }
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
            let jsondata = responseString?.data(using: .utf8)
            
            var jsonObject: Any
            do {
                jsonObject = try JSONSerialization.jsonObject(with: jsondata!) as Any
                if let obj = jsonObject as? NSDictionary {
                    print(obj["conversationId"] ?? (Any).self)
                    DispatchQueue.main.async {
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        appDelegate.user?.conversationID = obj.value(forKey:"conversationId") as? String
                        completionHandler(jsonObject as! NSDictionary)

                    }
                }
            } catch {
                print("error")
            }
        }
        task.resume()
    }
    
    
    /////// Send Message Api ////////
    func sendMessage(msgString: String, completionHandler :@escaping CompletionHandler)
    {
        // Getting userID
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let userID = appDelegate.user?.userID
        print(appDelegate.user?.conversationID ?? "default")
        let conversationID = appDelegate.user?.conversationID!
        // Send message
        let Url = String(format:API.baseURL + "/\(conversationID!)/activities")
        guard let serviceUrl = URL(string: Url) else { return }
        var parameterDictionary: Dictionary = [String: Any]()
        var dictionaryData: Dictionary = [String: Any]()
        dictionaryData ["from"] = ["id":userID]
        parameterDictionary = ["type" : "message", "text" : msgString]
        let temp = NSMutableDictionary(dictionary: parameterDictionary);
        temp.addEntries(from: dictionaryData)
        var requestsecond = URLRequest(url: serviceUrl)
        requestsecond.httpMethod = "POST"
        requestsecond.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        requestsecond.setValue(API.token, forHTTPHeaderField: "Authorization")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: temp, options: []) else {
            return
        }
        requestsecond.httpBody = httpBody
        
        let session = URLSession.shared
        session.dataTask(with: requestsecond) { (data, response, error) in
            if let response = response
            {
                print(response)
            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    print(json)
                    self.getResponseofMessage(completionHandler: completionHandler)
                }catch {
                    print(error)
                }
            }
            }.resume()
    }
    
    //// Get Send Message Response Api
    func getResponseofMessage(completionHandler :@escaping CompletionHandler)
    {
        //print(conversationid)
        // Send message
        var appDelegate: AppDelegate? = nil
        DispatchQueue.main.async{
            appDelegate = UIApplication.shared.delegate as? AppDelegate
        }
        
        let conversationID = appDelegate?.user?.conversationID!
        let Url = String(format: API.baseURL + "/\(conversationID!)/activities")
        guard let serviceUrl = URL(string: Url) else { return }
        var requestThird = URLRequest(url: serviceUrl)
        requestThird.httpMethod = "GET"
        requestThird.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        requestThird.setValue(API.token, forHTTPHeaderField: "Authorization")
        let session = URLSession.shared
        session.dataTask(with: requestThird) { (data, response, error) in
            if let response = response
            {
                print(response)
            }
            if let data = data {
                do {
                    let json :NSDictionary = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
                    print(json)
                    completionHandler(json)
                    
                }catch {
                    print(error)
                }
            }
            }.resume()
    }
}



