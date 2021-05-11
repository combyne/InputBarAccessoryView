//
//  String+Extensions.swift
//  InputBarAccessoryView
//
//  Created by Ryan Nystrom on 12/22/17.
//  Modified by Nathan Tannar on 09/18/18
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation

internal extension Character {
    
    static var space: Character {
        return " "
    }
}

extension StringProtocol {
    func isContainingSequencesOfWhitespaceLonger(than count: Int) -> Bool {
        // The documentation for 'CharacterSet.whitespaces' mentions that it contains
        // characters from the Unicode General Category Zs & CHARACTER TABULATION (U+0009)
        //
        // In the Regular Expression:
        // \p{Z} -> Unicode General Category Zs
        // \t -> CHARACTER TABULATION (U+0009)
        //
        // We want to match any sequence of space that is strictly longer than count.
        if let regularExpression = try? NSRegularExpression(pattern: "[\\p{Z}\\t]{\(count + 1),}") {
            let fullRange = NSRange(location: 0, length: self.utf16.count)

            let numberOfMatches = regularExpression.numberOfMatches(in: String(self), range: fullRange)
            return numberOfMatches > 0
        }

        return false
    }
}
