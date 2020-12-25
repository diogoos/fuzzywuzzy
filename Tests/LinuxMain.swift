import XCTest

import fuzzywuzzyTests

var tests = [XCTestCaseEntry]()
tests += FuzzywuzzyTests.allTests()
tests += UtilsTests.allTests()
XCTMain(tests)
