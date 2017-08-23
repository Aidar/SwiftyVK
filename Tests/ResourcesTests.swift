import Foundation
import XCTest
@testable import SwiftyVK

class ResourcesTests: XCTestCase {
    
    func test_suffixForPlatform() {
        // When
        let path = Resources.withSuffix("test")
        // Then
        #if os(OSX)
            XCTAssertEqual(path, "test_macOS")
        #elseif os(iOS)
            XCTAssertEqual(path, "test_iOS")
        #elseif os(tvOS)
            XCTAssertEqual(path, "test_tvOS")
        #elseif os(watchOS)
            XCTAssertEqual(path, "test_watchOS")
        #endif
    }
}
