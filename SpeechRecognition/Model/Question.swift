//
//  Question.swift
//  SpeechRecognition
//
//  Created by Admin on 14/06/18.
//  Copyright © 2018 DB. All rights reserved.
//

import UIKit

class Question: NSObject {
    var question: String
    var answer: String
    
    init (question : String, answer : String) {
        self.question = question
        self.answer = answer
    }
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.question, forKey: "question")
        aCoder.encode(self.answer, forKey: "answer")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard let question = aDecoder.decodeObject(forKey: "question") as? String,
            let answer = aDecoder.decodeObject(forKey:"answer") as? String
            else { return nil }
        self.question = question
        self.answer = answer
    }
}
