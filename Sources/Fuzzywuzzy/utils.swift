//
//  utils.swift
//
//  Created by Diogo Silva on 12/23/20.
//
import Foundation

internal extension String {
    /// Processes the String for analysis, by removing all
    /// non-alphaumeric characters (such as puncuation and
    /// emoji), lowercasing the string, and trimming leading
    /// and trailing whitespace.
    /// - Parameter stripNonAscii: Whether to aditionally remove
    /// all non-ASCII characters
    /// - Returns: the lowercased string including only
    /// aphanumeric characters, and with trimmed whitespace
    func fullyProcessed(stripNonAscii: Bool = false) -> String {
        var result = self

        // force to ascii if necessary
        if stripNonAscii { result = self.asciiOnly() }

        // replace non numbers or characters with whitespace (ie remove emoji)
        let mutable = NSMutableString(string: result)
        let regex = try! NSRegularExpression(pattern: "(?ui)\\W")
        regex.replaceMatches(in: mutable, range: NSRange(location: 0, length: mutable.length), withTemplate: " ")
        result = String(mutable)

        // make lowercase
        result = result.lowercased()

        // remove leading and trailing whitespace
        result = result.trimmingCharacters(in: .whitespaces)

        // return result
        return result
    }

    /// Remove all non-ASCII characters from
    /// the given string.
    func asciiOnly() -> String {
        filter { $0.isASCII }
    }


    /// Convert the string into a `UnsafePointer<Uint8>`,
    /// by converting it into UTF8 Data and copying that
    /// data into a pointer.
    ///
    /// This is mainly used for compatibilty with the
    /// CLevshtein library, which requires strings to be
    /// in this format.
    ///
    /// - Returns: A pointer to a UInt8 encoded version
    /// of the string
    func toPointer() -> UnsafePointer<UInt8>? {
        // Try to get data from string
        guard let stringData = data(using: String.Encoding.utf8, allowLossyConversion: false) else { return nil }

        // Create mutable pointer from data
        let dataMutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: stringData.count)

        // Copies the bytes to the Mutable Pointer
        stringData.copyBytes(to: dataMutablePointer, count: stringData.count)

        // Cast to regular UnsafePointer
        let dataPointer = UnsafePointer<UInt8>(dataMutablePointer)
        return dataPointer
    }

    /// The number of UTF16 blocks in the string
    ///
    /// Differently from the `.count` method, which counts
    /// characters, this method provides the size of the
    /// utf16 representation of the string. This is equivalent
    /// to calling `(string as NSString).length`
    var length: Int { utf16.count }

    /// Generate a string index range from character positions
    /// in the string
    func range(start: Int, end: Int) -> Range<String.Index> {
        index(startIndex, offsetBy: start)..<index(startIndex, offsetBy: end)
    }

    /// Sort the tokens (words) in the strings
    func sortTokens(forceAscii: Bool, fullProcess: Bool = true) -> String {
        // pull tokens
        var ts = fullProcess ? fullyProcessed() : self
        if forceAscii { ts = ts.asciiOnly() }
        let tokens = ts.components(separatedBy: " ")

        // sort tokens and join
        let sortedString = tokens.sorted().joined(separator: " ")
        return sortedString.trimmingCharacters(in: .whitespaces)
    }
}

internal extension UnsafeMutablePointer {
    /// Get the specified count of elements
    /// in the mutable pointer.
    func elements(count: Int) -> [Pointee] {
        let buffer = UnsafeBufferPointer(start: self, count: count);
        return Array(buffer)
    }
}


internal extension Double {
    /// Convert the Double into a percentage,
    /// round the result into an integer.
    func percentRound() -> Int {
        return Int((100 * self).rounded())
    }
}
