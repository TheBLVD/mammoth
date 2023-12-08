//
//  URL+Mastodon.swift
//  Mammoth
//
//  Created by Riley Howard on 5/3/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation


public extension URL {
    
    func isAccountURL() -> Bool {
        var isAccountURL = false
        
        // Make sure the path starts with an @, and has one or more characters,
        // but no "/[digits] after it (that would be a post URL).
        let urlPath = self.path
        if urlPath.hasPrefix("/@") {
            // It's OK if there's a /, but if there is anything after that,
            // this is not an account URL.
            if let slashIndexRange = urlPath.range(of: "/") {
                // Make sure there is nothing after the /
                let indexOfSlash: Int = urlPath.distance(from: urlPath.startIndex, to: slashIndexRange.lowerBound)
                if indexOfSlash == urlPath.count {
                    isAccountURL = true
                }
            } else {
                // no /; it's an account URL
                isAccountURL = true
            }
        }
        return isAccountURL
    }
    
    func isPostURL() -> Bool {
        // kick out any with a specific host
        if let urlHost = self.host,
           urlHost.hasSuffix("tiktok.com") {
            return false
        }
        
        // look for "/@" followed by "/ and one or more digits" in the path
        let urlPath = self.path
        let regex = try? NSRegularExpression(pattern: "/@.+/[0-9]+", options: [])
        if let _ = regex?.firstMatch(in: urlPath, range: NSRange(location: 0, length: urlPath.utf16.count)) {
            return true
        }
        
        return false
    }
    
    func postIDFromURL() -> String {
        var postID = ""
        if self.isPostURL() {
            // Get the string of digits after the /@.../ from the path
            let urlPath = self.path
            let regex = try? NSRegularExpression(pattern: "/@.+/", options: [])
            if let atMatch = regex?.firstMatch(in: urlPath, range: NSRange(location: 0, length: urlPath.utf16.count)) {
                // Starting after the /, get the string of digits
                let regex2 = try? NSRegularExpression(pattern: "[0-9]+", options: [])
                let indexOfFirstDigit = String.Index(utf16Offset: atMatch.range.upperBound, in: urlPath)
                let remainingURL = String(urlPath.suffix(from: indexOfFirstDigit))
                if let digitsMatch = regex2?.firstMatch(in: remainingURL, range: NSRange(location: 0, length: remainingURL.utf16.count)) {
                    let range = NSRange(location: digitsMatch.range.lowerBound, length: digitsMatch.range.length)
                    let nsstring = remainingURL as NSString
                    postID = nsstring.substring(with: range)
                }
            }
        } else {
            log.warning("\(self) is not a post URL")
        }
        return postID
    }
    
    
    
}
