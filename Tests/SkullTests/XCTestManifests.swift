import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(ColumnTests.allTests),
    testCase(ConnectionTests.allTests),
    testCase(ErrorTests.allTests),
    testCase(ExecTests.allTests),
    testCase(QueryTests.allTests),
    testCase(RowTests.allTests),
    testCase(SerialTests.allTests),
    testCase(UpdateTests.allTests),
  ]
}
#endif
