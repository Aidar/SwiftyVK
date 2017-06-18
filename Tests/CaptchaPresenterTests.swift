import Foundation
import XCTest
@testable import SwiftyVK

class CaptchaPresenterTests: XCTestCase {
    
    func makeContext() -> (presenter: CaptchaPresenter, webControllerMaker: CaptchaControllerMakerMock) {
        let controllerMaker = CaptchaControllerMakerMock()
        
        let presenter = CaptchaPresenterImpl(
            uiSyncQueue: DispatchQueue.global(),
            controllerMaker: controllerMaker,
            timeout: 1
        )
        return (presenter, controllerMaker)
    }
    
    
    func test_present_throwCantMakeCaptchaController() {
        // Given
        let context = makeContext()
        // When
        do {
            _ = try context.presenter.present(rawCaptchaUrl: "", dismissOnFinish: false)
            XCTFail("Expression should throw error")
        } catch let error {
            // Then
            XCTAssertEqual(error as? SessionError, .cantMakeCaptchaController)
        }
    }
}
