//
//  DictionaryExtension.swift
//  MovieApp
//
//  Created by Arthur Alvarez on 03/11/16.
//  Copyright © 2016 Arthur Alvarez. All rights reserved.
//

import Foundation

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}
