import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(FuzzywuzzyTests.allTests),
        testCase(UtilsTests.allTests)
    ]
}
#endif
