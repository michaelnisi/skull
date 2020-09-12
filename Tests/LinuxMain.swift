import XCTest

import SkullTests

var tests = [XCTestCaseEntry]()
tests += SkullTests.__allTests()

XCTMain(tests)
