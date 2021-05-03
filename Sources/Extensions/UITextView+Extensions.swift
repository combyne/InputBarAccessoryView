//
//  UITextView+Extensions.swift
//  InputBarAccessoryView
//
//  Created by Nathan Tannar on 09/18/18.
//  Copyright © 2018 Nathan Tannar. All rights reserved.
//

import UIKit

public extension UITextView {

    typealias Match = (prefix: String, word: String, range: NSRange)

    var caretRange: NSRange? {
        guard let selectedRange = self.selectedTextRange else { return nil }
        return NSRange(
            location: offset(from: beginningOfDocument, to: selectedRange.start),
            length: offset(from: selectedRange.start, to: selectedRange.end)
        )
    }

    /// Returns the last substring matching the prefixes and the delimiter sets provided.
    /// The prefix is included in the substring, but the delimiter is not.
    ///
    /// If there are multiple matches, only the most recent one is returned (i. e. the closest to
    /// the position of the caret).
    ///
    /// The substring must:
    /// - start with one of strings contained in `prefixes`;
    /// - end with any of the characters contained in `CharacterSet`;
    /// - be contained between the beginning of the document and the upper boundary of the caret.
    ///
    /// - Parameters:
    ///   - prefixes: The prefixes to match against.
    ///   - delimiterSet: A set of character delimiting the range.
    /// - Returns: a `Match` containing the string, prefix and range if found, `nil` otherwise.
    func find(prefixes: Set<String>, with delimiterSet: CharacterSet, maxSpaceCountAllowed: Int = 0) -> Match? {
        find(prefixes: prefixes, globalDelimiterSet: delimiterSet, maxSpaceCountAllowed: maxSpaceCountAllowed)
    }

    /// Returns the last substring matching the prefixes and the delimiter sets provided.
    /// The prefix is included in the substring, but the delimiter is not.
    ///
    /// If there are multiple matches, only the most recent one is returned (i. e. the closest to
    /// the position of the caret). This methods accepts a dictionary of delimiter sets, so
    /// that different sets can be used depending on the prefix.
    ///
    /// The substring must:
    /// - start with one of strings contained in `prefixes`;
    /// - end with any of the characters contained in the `CharacterSet` matching the prefix;
    /// - be contained between the beginning of the document and the upper boundary of the caret.
    ///
    /// - Parameters:
    ///   - prefixes: The prefixes to match against.
    ///   - delimiterSets: A dictionary of character sets delimiting the range.
    /// - Returns: a `Match` containing the string, prefix and range if found, `nil` otherwise.
    func find(prefixes: Set<String>,
              with delimiterSets: [String: CharacterSet],
              maxSpaceCountAllowed: Int = 0) -> Match? {
        find(prefixes: prefixes, delimiterSets: delimiterSets, maxSpaceCountAllowed: maxSpaceCountAllowed)
    }

    /// Returns the last substring matching the prefixes and the delimiter sets provided.
    /// The prefix is included in the substring, but the delimiter is not.
    ///
    /// If there are multiple matches, only the most recent one is returned (i. e. the closest to
    /// the position of the caret). This methods accepts a dictionary of delimiter sets, so
    /// that different sets can be used depending on the prefix.
    ///
    /// The substring must:
    /// - start with one of strings contained in `prefixes`;
    /// - end with any of the characters contained in the `CharacterSet` matching the prefix;
    ///   alternatively, if `delimiterSets` is `nil` or doesn't contain the current `prefix`,
    ///   `globalDelimiterSet` is used instead;
    /// - be contained between the beginning of the document and the upper boundary of the caret.
    ///
    /// - Parameters:
    ///   - prefixes: The prefixes to match against.
    ///   - delimiterSets: A dictionary of character sets delimiting the range.
    ///   - globalDelimiterSet: A set of character delimiting the range, used as
    ///                         a fallback for all prefixes if `delimiterSets` is `nil`
    ///                         or doesn't contain a given prefix.
    /// - Returns: a `Match` containing the string, prefix and range if found, `nil` otherwise.
    func find(prefixes: Set<String>,
              delimiterSets: [String: CharacterSet]? = nil,
              globalDelimiterSet: CharacterSet? = nil,
              maxSpaceCountAllowed: Int = 0) -> Match? {
        guard prefixes.count > 0 else { return nil }

        let matches: [Match] = prefixes.compactMap { prefix in
            guard let delimiterSet = delimiterSets?[prefix] ?? globalDelimiterSet else { return nil }
            return find(prefix: prefix, with: delimiterSet, maxSpaceCountAllowed: maxSpaceCountAllowed)
        }
        let sorted = matches.sorted { a, b in
            return a.range.lowerBound > b.range.lowerBound
        }
        return sorted.first
    }

    /// Returns the last substring matching the prefix and the delimiter sets provided.
    /// The prefix is included in the substring, but the delimiter is not.
    ///
    /// If there are multiple matches, only the most recent one is returned (i. e. the closest to
    /// the position of the caret).
    ///
    /// The substring must:
    /// - start with one of strings contained in `prefixes`;
    /// - end with any of the characters contained in the `CharacterSet` matching the prefix;
    ///   alternatively, if `delimiterSets` is `nil` or doesn't contain the current `prefix`,
    ///   `globalDelimiterSet` is used instead;
    /// - be contained between the beginning of the document and the upper boundary of the caret.
    ///
    /// - Parameters:
    ///   - prefixes: The prefixes to match against.
    ///   - delimiterSet: A set of character delimiting the range.
    /// - Returns: a `Match` containing the string, prefix and range if found, `nil` otherwise.
    func find(prefix: String, with delimiterSet: CharacterSet?, maxSpaceCountAllowed: Int = 0) -> Match? {
        guard !prefix.isEmpty else { return nil }
        guard let caretRange = self.caretRange else { return nil }
        guard let cursorRange = Range(caretRange, in: text) else { return nil }

        // We're only interested in the range between the beginning of the document
        // and the upper bound of the caret range (which is the same as the caret position
        // when it has a zero length).
        let leadingText = text[..<cursorRange.upperBound]

        // Iterating through each characters of the prefix, since it can contain
        // multiple characters, to make sure we're matching the full prefix and not just
        // the first character.
        var prefixStartIndex: String.Index = leadingText.startIndex
        var lastMatchedCharacterIndex: String.Index = leadingText.startIndex
        for (i, char) in prefix.enumerated() {
            guard let index = leadingText.lastIndex(of: char) else { return nil }
            if i == 0 {
                // When it's the first character and an index was found,
                // we assume it's the start of the prefix.
                prefixStartIndex = index
                lastMatchedCharacterIndex = index
            } else if leadingText.distance(from: lastMatchedCharacterIndex, to: index) == 1 {
                // When it's not the first character, we check the distance from
                // the previous matched character. If it's 1, then the two characters
                // are adjacent and part of the same prefix. We can keep iterating.
                lastMatchedCharacterIndex = index
                continue
            } else {
                // If none of the above conditions are true, then we assume the prefix
                // doesn't exist.
                //
                // Note that if we wanted to allow parts of the prefix to be present in
                // the substring, we'd need to keep searching for a valid prefix between
                // the beginning of the document and 'text[..<leadingText.lastIndex(of: prefix[0])]',
                // but that's not the case at the moment.
                return nil
            }
        }

        // Extracting the word based on the computed indices.
        let wordRange = prefixStartIndex..<cursorRange.upperBound
        let word = leadingText[wordRange]

        // Sometimes, you may want to allow a number of contiguous whitespace characters
        // inside a match, while still keeping the whitespace as a delimiter.
        guard isWordValid(word, delimiterSet: delimiterSet, maxSpaceCountAllowed: maxSpaceCountAllowed) else {
            return nil
        }

        // Now that we have the unicode-aware indices, we can convert them to
        // UTF-16 offsets and be certain they will point to intended characters
        // (and not point to the middle of a cluster).
        let location = wordRange.lowerBound.utf16Offset(in: leadingText)
        let length = wordRange.upperBound.utf16Offset(in: leadingText) - location
        let range = NSRange(location: location, length: length)
        
        return (String(prefix), String(word), range)
    }


    /// Returns `true` is the given `word` is a valid match, based on the number of allowed spaces and
    /// the delimiter set.
    ///
    /// - Parameters:
    ///   - word: The word to test.
    ///   - delimiterSet: A set of delimiting characters that can't be contained in `word`.
    ///   - maxSpaceCountAllowed: The number of contiguous spaces allowed within `word`.
    /// - Returns: `true` if the word is valid, `false` otherwise.
    private func isWordValid(_ word: Substring, delimiterSet: CharacterSet?, maxSpaceCountAllowed: Int) -> Bool {
        if maxSpaceCountAllowed > 0 {
            if word.isContainingSequencesOfWhitespaceLonger(than: maxSpaceCountAllowed) {
                return false
            }

            // At this point, there's either no whitespace, or a number of spaces lower
            // than `maxSpaceCountAllowed`. Both of those cases are valid, so we can
            // safely remove the `.whitespace` set from the delimiter set and test if any
            // delimiting characters are present in the word.
            if var delimiterSet = delimiterSet {
                delimiterSet.subtract(.whitespaces)
                if word.rangeOfCharacter(from: delimiterSet) != nil {
                    return false
                }
            }
        } else {
            // If the word contains one of the delimiting characters, then it's not an
            // acceptable prefix. Same caveat as above, if we wanted to allow characters
            // contained in a multi-character prefix, we'd have to check whether there
            // are other matches earlier in the range.
            if let delimiterSet = delimiterSet, word.rangeOfCharacter(from: delimiterSet) != nil {
                return false
            }
        }

        return true
    }
}
