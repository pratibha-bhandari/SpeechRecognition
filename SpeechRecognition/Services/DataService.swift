//
//  DataService.swift
//  SpeechRecognition
//
//  Created by Admin on 12/06/18.
//  Copyright © 2018 DB. All rights reserved.
//

import UIKit

class DataService {
    
    //static let sharedInstance  = DataService()
    static let sharedInstance: DataService = {
        let instance = DataService()
        instance.loadData()
        // setup code
        return instance
    }()
    private init() {}
    var activities: [Activity] = []
    
    var filePath: String {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        print("this is the url path in the documentDirectory \(String(describing: url))")
        return (url!.appendingPathComponent("Data").path)
    }
    
    public func saveData(item: [Activity]) {
        self.activities.append(contentsOf: item)
        print("filePath -- \(filePath)")
        NSKeyedArchiver.archiveRootObject(self.activities, toFile: filePath)
        loadData()
    }
    
    private func loadData() {
        if let ourData = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [Activity] {
            self.activities = ourData
        }
    }
}
