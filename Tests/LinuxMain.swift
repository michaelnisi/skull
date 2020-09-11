import XCTest

import SkullTests

var tests = [XCTestCaseEntry]()
tests += SkullTests.allTests()
XCTMain(tests)
