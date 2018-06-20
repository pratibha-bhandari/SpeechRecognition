//
//  Extensions.swift
//  SpeechRecognition
//
//  Created by Admin on 13/06/18.
//  Copyright © 2018 DB. All rights reserved.
//

import Foundation
extension Array where Element: Hashable {
    
    func next(item: Element) -> Element? {
        if let index = self.index(of: item), index + 1 <= self.count {
            return index + 1 == self.count ? self[0] : self[index + 1]
        }
        return nil
    }
    
    func prev(item: Element) -> Element? {
        if let index = self.index(of: item), index >= 0 {
            return index == 0 ? self.last : self[index - 1]
        }
        return nil
    }
}
