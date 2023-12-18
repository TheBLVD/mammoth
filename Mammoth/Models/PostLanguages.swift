//
//  PostLanguages.swift
//  Mammoth
//
//  Created by Riley on 12/15/23
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class PostLanguages {
    
    static var shared = PostLanguages()
    
    private (set) var postLanguage: String {
        didSet {
            UserDefaults.standard.setValue(postLanguage, forKey: "postLanguages")
        }
    }
    private (set) var postLanguages: [String] {
        didSet {
            UserDefaults.standard.setValue(postLanguages, forKey: "postLanguages")
        }
    }
    
    init() {
        postLanguage = UserDefaults.standard.value(forKey: "postLanguage") as? String ?? Locale.current.languageCode ?? "EN"
        postLanguages = UserDefaults.standard.value(forKey: "postLanguages") as? [String] ?? []
        if postLanguages.count == 0 {
            postLanguages = [postLanguage]
        }
        if !postLanguages.contains(postLanguage) {
            postLanguages.append(postLanguage)
        }
    }
        
    // Will add if needed, and also move the language to the start of the array
    public func selectPostLanguage(_ language: String) {
        // First, add to the list if necessary
        if !postLanguages.contains(language) {
            postLanguages.append(language)
            // Trim to 3 most recent languages
            while postLanguages.count > 3 {
                postLanguages.removeFirst()
            }
        }
        
        // Then select it
        postLanguage = language
    }
    
    // Will remove the language, unless it is the last one
    public func removePostLanguage(_ language: String) {
        if postLanguages.count > 1 {
            if let index = postLanguages.firstIndex(of: language) {
                postLanguages.remove(at: index)
            }
        }
        if !postLanguages.contains(postLanguage) {
            postLanguage = postLanguages[0]
        }
    }
    
}

