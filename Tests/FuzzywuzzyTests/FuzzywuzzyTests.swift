import XCTest
@testable import Fuzzywuzzy

final class FuzzywuzzyTests: XCTestCase {
    let s1 = "new york mets"
    let s1a = "new york mets"
    let s1b = "york new mets"
    let s2 = "new YORK mets"
    let s3 = "the wonderful new york mets"
    let s4 = "new york mets vs atlanta braves"
    let s5 = "atlanta braves vs new york mets"
    let s6 = "new york mets - atlanta braves"
    let s7 = "new york city mets - atlanta braves"

    // test silly corner cases
    let s8 = "{"
    let s8a = "{"
    let s9 = "{a"
    let s9a = "{a"
    let s10 = "a{"
    let s10a = "{b"

    func testEqualStringsRatio() {
        XCTAssertEqual(s1.ratio(to: s1a), 100)
        XCTAssertEqual(s8.ratio(to: s8a), 100)
        XCTAssertEqual(s9.ratio(to: s9a), 100)
    }

    func testCaseInsensitive() {
        XCTAssertNotEqual(s1.ratio(to: s2, fullProcess: false), 100)
        XCTAssertEqual(s1.ratio(to: s2), 100)
    }

    func testPartialRatio() {
        XCTAssertEqual(s1.partialRatio(to: s3), 100)
    }

    func testTokenSortRatio() {
        XCTAssertEqual(TokenFunctions.tokenSortRatio(s1, s1b), 100)
    }

    func testPartialTokenSortRatio() {
        XCTAssertEqual(TokenFunctions.partialTokenSortRatio(s1, s1a), 100)
        XCTAssertEqual(TokenFunctions.partialTokenSortRatio(s4, s5), 100)
        XCTAssertEqual(TokenFunctions.partialTokenSortRatio(s8, s8a, fullProcess: false), 100)
        XCTAssertEqual(TokenFunctions.partialTokenSortRatio(s9, s9a, fullProcess: false), 100)
        XCTAssertEqual(TokenFunctions.partialTokenSortRatio(s9, s9a, fullProcess: true), 100)
        XCTAssertEqual(TokenFunctions.partialTokenSortRatio(s10, s10a, fullProcess: false), 50)
    }

    func testTokenSetRatio() {
        XCTAssertEqual(TokenFunctions.tokenSetRatio(s4, s5), 100)
        XCTAssertEqual(TokenFunctions.tokenSetRatio(s8, s8a, fullProcess: false), 100)
        XCTAssertEqual(TokenFunctions.tokenSetRatio(s9, s9a, fullProcess: true), 100)
        XCTAssertEqual(TokenFunctions.tokenSetRatio(s9, s9a, fullProcess: false), 100)
        XCTAssertEqual(TokenFunctions.tokenSetRatio(s10, s10a, fullProcess: false), 50)
    }

    func testPartialTokenSetRatio() {
        XCTAssertEqual(TokenFunctions.partialTokenSetRatio(s4, s7), 100)
        XCTAssertEqual(TokenFunctions.partialTokenSetRatio(s10, s10a, fullProcess: false), 50)
    }

    func testWeightedRatioEqual() {
        XCTAssertEqual(s1.weightedRatio(to: s1a), 100)
    }

    func testWeightedRatioCaseInsensitive() {
        XCTAssertEqual(s1.weightedRatio(to: s2), 100)
    }

    func testWeightedRatioPartialMatch() {
        // a partial match is scaled by .9
        XCTAssertEqual(s1.weightedRatio(to: s3), 90)
    }

    func testWeightedRatioMisorderedMatch() {
        // misordered full matches are scaled by .95
        XCTAssertEqual(s4.weightedRatio(to: s5), 95)
    }

    func testEmptyStringsScore100() {
        XCTAssertEqual("".ratio(to: ""), 100)
        XCTAssertEqual("".partialRatio(to: ""), 100)
        XCTAssertEqual("".weightedRatio(to: ""), 100)
    }

    // Issue 7 originally applies to the Python version
    // of fuzzywuzzy, but this port should resolve it.
    // https://github.com/seatgeek/fuzzywuzzy/issues/7
    func testIssue7() {
        let s1 = "HSINCHUANG"
        let s2 = "SINJHUAN"
        let s3 = "LSINJHUANG DISTRIC"
        let s4 = "SINJHUANG DISTRICT"

        XCTAssertTrue(s1.partialRatio(to: s2) > 75)
        XCTAssertTrue(s1.partialRatio(to: s3) > 75)
        XCTAssertTrue(s1.partialRatio(to: s4) > 75)
    }

    func testRatioUnicodeString() {
        let s1 = "\u{00C1}"
        let s2 = "ABCD"
        XCTAssertEqual(s1.ratio(to: s2), 0)
    }

    func testPartialRatioUnicodeString() {
        let s1 = "\u{00C1}"
        let s2 = "ABCD"
        XCTAssertEqual(s1.partialRatio(to: s2), 0)
    }

    func testWeightedRatioUnicodeString() {
        var s1 = "\u{00C1}"
        var s2 = "ABCD"
        XCTAssertEqual(s2.weightedRatio(to: s1, forceAscii: false), 0)

        s1 = "\u{043f}\u{0441}\u{0438}\u{0445}\u{043e}\u{043b}\u{043e}\u{0433}"
        s2 = "\u{043f}\u{0441}\u{0438}\u{0445}\u{043e}\u{0442}\u{0435}\u{0440}\u{0430}\u{043f}\u{0435}\u{0432}\u{0442}"
        XCTAssert(s1.weightedRatio(to: s2, forceAscii: false) > 0)

        // Chinese
        s1 = "\u{6211}\u{4e86}\u{89e3}\u{6570}\u{5b66}"
        s2 = "\u{6211}\u{5b66}\u{6570}\u{5b66}"
        XCTAssert(s1.weightedRatio(to: s2, forceAscii: false) > 0)
    }

    func testTokenSetForceAscii() {
        let s1 = "ABCD\u{00C1} EFGH\u{00C1}"
        let s2 = "ABCD EFGH"
        XCTAssertEqual(TokenFunctions.tokenSet(s1: s1, s2: s2, forceAscii: true), 100)
        XCTAssertLessThan(TokenFunctions.tokenSet(s1: s1, s2: s2, forceAscii: false), 100)
    }

    func testTokenSortForceAscii() {
        let s1 = "ABCD\u{00C1} EFGH\u{00C1}"
        let s2 = "ABCD EFGH"
        XCTAssertEqual(TokenFunctions.tokenSort(s1: s1, s2: s2, forceAscii: true), 100)
        XCTAssertLessThan(TokenFunctions.tokenSort(s1: s1, s2: s2, forceAscii: false), 100)
    }

    func testREADME() {
        // make sure that the results displayed are accurate
        XCTAssertEqual("this is a test".ratio(to: "did you know this is a test"), 68)
        XCTAssertEqual("this is a test".partialRatio(to: "did you know this is a test"), 100)
        XCTAssertEqual("this is an interesting test".weightedRatio(to: "this is a test!"), 86)

        // makes sure initializer and methods still exist
        let matcher = StringMatcher(compare: "this is interesting", to: "this is cool")
        _ = matcher.ratio()
        _ = matcher.opcodes()
        _ = matcher.matchingBlocks()


        // Sorted ratio
        XCTAssertEqual("fuzzy wuzzy was a bear".ratio(to: "wuzzy fuzzy was a bear"), 91)
        XCTAssertEqual(TokenFunctions.tokenSortRatio("fuzzy wuzzy was a bear", "wuzzy fuzzy was a bear"), 100)

        // Set-based ratio
        XCTAssertEqual(TokenFunctions.tokenSortRatio("fuzzy was a bear", "fuzzy fuzzy was a bear"), 84)
        XCTAssertEqual(TokenFunctions.tokenSetRatio("fuzzy was a bear", "fuzzy fuzzy was a bear"), 100)
    }

    static var allTests = [
        ("Test that the ratio is 100 when comparing equal strings", testEqualStringsRatio),
        ("Test that the ratios are case insensitive when fully processed", testCaseInsensitive),
        ("Test that partial ratio is 100 when comparing substrings", testPartialRatio),
        ("Test that tokenSortRatio correctly identifies equal strings in different orders", testTokenSortRatio),
        ("Test that partial tokens are correctly ratio'd when sorted", testPartialTokenSortRatio),
        ("Test that tokenSetratio correctly processes similar strings", testTokenSetRatio),
        ("Test calculating set ratio with partial tokens", testPartialTokenSetRatio),
        ("Test that weighted ratio returns 100 on equal strings", testWeightedRatioEqual),
        ("Test that weighted ratio is case insensitive", testWeightedRatioCaseInsensitive),
        ("Test that weighted ratio correctly scales a partial match", testWeightedRatioPartialMatch),
        ("Test that weighred ratio scales correctly equal strings in different orders", testWeightedRatioMisorderedMatch),
        ("Assert that when comparing empty strings, the ratio is always 100", testEmptyStringsScore100),
        ("Assert that a subtraction error does not cause substrings to be misidentified", testIssue7),
        ("Test that unicode strings are not misidentified when calculating ratio", testRatioUnicodeString),
        ("Test that unicode strings are not misidentified when calculating partialRatio", testPartialRatioUnicodeString),
        ("Test weightedRatio with a variety of unicode strings", testWeightedRatioUnicodeString),
        ("Test tokenSet returns correct results when removing and when keeping non-ASCII characters", testTokenSetForceAscii),
        ("Test tokenSort returns correct results when removing and when keeping non-ASCII characters", testTokenSetForceAscii),
        ("Test that the code examples in the README file are accurate", testREADME)
    ]
}
