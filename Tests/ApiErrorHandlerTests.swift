import Foundation
import XCTest
@testable import SwiftyVK

class ApiErrorHandlerTests: XCTestCase {
    
    func test_callLogIn_whenHandledAccessDeniedError() {
        // Given
        let context = makeContext()
        let error = ApiError(code: 5)
        var onLogInCallCount = 0
        
        context.executor.onLogIn = {
            onLogInCallCount += 1
            return [:]
        }
        // When
        do {
            _ = try context.handler.handle(error: error)
            // Then
            XCTAssertEqual(onLogInCallCount, 1)
        } catch let error {
            XCTFail("Expression throw unexpected error \(error)")
        }
    }
    
    func test_callCaptcha_whenHandledCaptchaNeededError() {
        // Given
        let context = makeContext()
        let error = ApiError(
            code: 14,
            otherInfo: [
                "captcha_sid": "",
                "captcha_img": ""
            ]
        )
        var onCaptchaCallCount = 0
        
        context.executor.onCaptcha = {
            onCaptchaCallCount += 1
            return ""
        }
        // When
        do {
            _ = try context.handler.handle(error: error)
            // Then
            XCTAssertEqual(onCaptchaCallCount, 1)
        } catch let error {
            XCTFail("Expression throw unexpected error \(error)")
        }
    }
    
    func test_throwErrorBack_whenHandledCaptchaNeededErrorWithoutParameters() {
        // Given
        let context = makeContext()
        let error = ApiError(code: 14)

        // When
        do {
            _ = try context.handler.handle(error: error)
            // Then
            XCTFail("Expression should throw error")
        } catch let throwedError {
            XCTAssertEqual(error.toVk, throwedError.asVk)
        }
    }
    
    func test_callValidate_whenHandledValidationNeededError() {
        // Given
        let context = makeContext()
        let error = ApiError(
            code: 17,
            otherInfo: [
                "redirect_uri": "http://te.st"
            ]
        )
        var onValidateCallCount = 0
        
        context.executor.onValidate = {
            onValidateCallCount += 1
        }
        // When
        do {
            _ = try context.handler.handle(error: error)
            // Then
            XCTAssertEqual(onValidateCallCount, 1)
        } catch let error {
            XCTFail("Expression throw unexpected error \(error)")
        }
    }
    
    func test_throwErrorBack_whenHandledValidationNeededErrorWithoutParameters() {
        // Given
        let context = makeContext()
        let error = ApiError(code: 17)
        
        // When
        do {
            _ = try context.handler.handle(error: error)
            // Then
            XCTFail("Expression should throw error")
        } catch let throwedError {
            XCTAssertEqual(error.toVk, throwedError.asVk)
        }
    }
    
    func test_throwErrorBack_whenHandledUnknownError() {
        // Given
        let context = makeContext()
        let error = ApiError(code: 0)
        // When
        do {
            _ = try context.handler.handle(error: error)
            // Then
            XCTFail("Expression should throw error")
        } catch let throwedError {
            XCTAssertEqual(error.toVk, throwedError.asVk)
        }
    }
}

private func makeContext() -> (executor: ApiErrorExecutorMock, handler: ApiErrorHandler) {
    let executor = ApiErrorExecutorMock()
    let handler = ApiErrorHandlerImpl(executor: executor)
    return (executor, handler)
}
