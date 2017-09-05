import Foundation
import XCTest
@testable import SwiftyVK

class CustomMethodTests: XCTestCase {
    
    func test_customName_equalsToMethodName() {
        // When
        let method = VKAPI.Custom.method(name: "test").toRequest().type.apiMethod
        // Then
        XCTAssertEqual(method, "test")
    }
    
    func test_remoteName_equalsToMethodName() {
        // When
        let method = VKAPI.Custom.remote(method: "test").toRequest().type.apiMethod
        // Then
        XCTAssertEqual(method, "execute.test")
    }
    
    func test_executeName_equalsToExecute() {
        // When
        let method = VKAPI.Custom.execute(code: "").toRequest().type.apiMethod
        // Then
        XCTAssertEqual(method, "execute")
    }
    
    func test_executeCode_equalsToParameters() {
        // When
        let parameters = VKAPI.Custom.execute(code: "code").toRequest().type.parameters
        // Then
        XCTAssertEqual(parameters?[VK.Arg.code] ?? "", "code")
    }
    
    func test_parameters_isEmpty() {
        // When
        let parameters = VKAPI.Custom.method(name: "test", parameters: .empty).toRequest().type.parameters
        // Then
        XCTAssertEqual(parameters?.isEmpty, true)
    }
    
    func test_parameters_equalsToMethodParameters() {
        // When
        let parameter = [VK.Arg.userId: "1"]
        let parameters = VKAPI.Custom.method(name: "test", parameters: parameter).toRequest().type.parameters
        // Then
        XCTAssertEqual(parameters?[VK.Arg.userId] ?? "", "1")
    }
    
    func test_callSessionSend_whenMethodSended() {
        // Given
        var sendCallCount = 0
        
        (VK.sessions?.default as? SessionMock)?.onSend = { request in
            sendCallCount += 1
        }
        // When
        VKAPI.Custom.method(name: "test").send()
        // Then
        XCTAssertEqual(sendCallCount, 1)
    }
}

