//
//  UtilsTests.swift
//
//  Created by Diogo Silva on 12/24/20.
//

import XCTest
@testable import Fuzzywuzzy
import Levenshtein

final class UtilsTests: XCTestCase {
    /// Mixed strings, simulating user input
    static let mixedStrings = [
        "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
        "C'est la vie",
        "Ça va?",
        "Cães danados",
        "¬Camarões assados",
        "a¬ሴ€耀",
        "Á"
    ]

    /// Mixed strings, removing all non-ascii characters.
    /// Expected output for calling .asciiOnly() in each
    /// of the original stirngs
    static let asciiStrings = [
        "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
        "C'est la vie",
        "a va?",
        "Ces danados",
        "Camares assados",
        "a",
        ""
    ]

    /// Mixed strings, lowercased, removing all non-alphanumeric
    /// characters. Expected output for calling .fullyProcessed()
    /// in each of the original strings
    static let fullProcessStrings = [
        "lorem ipsum is simply dummy text of the printing and typesetting industry",
        "c est la vie",
        "ça va",
        "cães danados",
        "camarões assados",
        "a ሴ 耀",
        "á"
    ]

    /// Mixed strings, lowercased, removing all non-alphanumeric
    /// and non-ascii characters. Expected output for calling
    /// .fullyProcessed(stripNonAscii: true) in each of the
    /// original strings
    static let fullProcessAsciiStrings = [
        "lorem ipsum is simply dummy text of the printing and typesetting industry",
        "c est la vie",
        "a va",
        "ces danados",
        "camares assados",
        "a",
        ""
    ]

    func testAsciiConversion() {
        XCTAssert(Self.mixedStrings.map { $0.asciiOnly() } == Self.asciiStrings)
    }

    func testFullProcess() {
        XCTAssert(Self.mixedStrings.map { $0.fullyProcessed() } == Self.fullProcessStrings)
    }

    func testFullProcessForceAscii() {
        XCTAssert(Self.mixedStrings.map { $0.fullyProcessed(stripNonAscii: true) } == Self.fullProcessAsciiStrings)
    }

    func testPercentRound() {
        let conversionTable: [Double: Int] = [
            0.1121: 11,
            0.2268: 23,
            0.3: 30,
            0.38762109123819203: 39,
            2/3: 67,
            1: 100,
            2.555: 256
        ]

        for row in conversionTable {
            let result = row.key.percentRound()
            XCTAssert(result == row.value, "Expected to convert \(row.key), to \(row.value), instead got \(result)")
        }
    }

    func testStringRange() {
        let string = "Hello world!"
        let range = string.range(start: 6, end: 11)
        let substring = String(string[range])
        XCTAssert(substring == "world")
    }

    func testStringLengthNSStringEquivalence() {
        let string = "This is a string with a somewhat large count 👏🎅 and it has emoji!"
        XCTAssert(string.length == (string as NSString).length)
    }

    func testStringTokenOrdering() {
        let conversionTable = [
            "dogs are very cute": "are cute dogs very",
            "  whitespace  also works": "also whitespace works",
            "aaaac aaaab": "aaaab aaaac"
        ]
        for row in conversionTable {
            let result = row.key.sortTokens(forceAscii: false)
            XCTAssert(result == row.value, "Expected to convert \(row.key), to \(row.value), instead got \(result)")
        }
    }

    func testMutablePointerExtraction() {
        var array = ["hello", "world", "swift", "c"]
        var pointer: UnsafeMutablePointer<String>? = nil
        array.withUnsafeMutableBufferPointer({ pointer = UnsafeMutablePointer($0.baseAddress) })
        XCTAssert(pointer != nil)
        let extracted = pointer!.elements(count: array.count)
        XCTAssert(extracted == array)
    }

    func testStringPointer() {
        let string = "Hello world"
        let pointer = string.toPointer()

        XCTAssert(pointer != nil)

        let data = Data(bytes: pointer!, count: string.length)
        let extracted = String(data: data, encoding: .utf8)

        XCTAssert(extracted == string)
    }

    static var allTests = [
        ("Test converting to ASCII", testAsciiConversion),
        ("Test string full processing", testFullProcess),
        ("Test convienence percentage conversion and rounding method", testPercentRound),
        ("Test python-like string range selection", testStringRange),
        ("Test that String.length is equivalent to NSString.length", testStringLengthNSStringEquivalence),
        ("Test that UnsafeMutablePointer.elements returns all elements stored in pointer", testMutablePointerExtraction),
        ("Test that String.toPointer returns a valid pointer", testStringPointer)
    ]
}
