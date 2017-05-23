import XCTest
@testable import SwiftyVK

final class SessionTests: BaseTestCase {
    
    var sessionObjects: (SessionImpl, TaskShedulerMock, AttemptShedulerMock, AuthorizatorMock, TokenStorageMock) {
        let taskSheduler = TaskShedulerMock()
        let attemptSheduler = AttemptShedulerMock()
        let authorizator = AuthorizatorMock()
        let tokenStorage = TokenStorageMock()
        
        let session = SessionImpl(
            taskSheduler: taskSheduler,
            attemptSheduler: attemptSheduler,
            authorizator: authorizator,
            tokenStorage: tokenStorage,
            taskMaker: dependencyBoxMock
        )
        
        return (session, taskSheduler, attemptSheduler, authorizator, tokenStorage)
    }
    
    func test_sheduleTask() {
        // Given
        let (session, taskSheduler, _, _, _) = sessionObjects
        let task = TaskMock()
        // Then
        try? session.shedule(task: task, concurrent: true)
        // When
        XCTAssertEqual(taskSheduler.sheduleCallCount, 1)
    }
    
    func test_sheduleAttempt() {
        // Given
        let (session, _, attemptSheduler, _, _) = sessionObjects
        let attempt = AttemptMock()
        // Then
        try! session.shedule(attempt: attempt, concurrent: true)
        // When
        XCTAssertEqual(attemptSheduler.sheduleCallCount, 1)
    }
    
    func test_send() {
        // Given
        let (session, taskSheduler, _, _, _) = sessionObjects
        let request = Request(of: .url(""))
        // Then
        _ = session.send(request: request, callbacks: .empty)
        // When
        XCTAssertEqual(taskSheduler.sheduleCallCount, 1)
    }
    
    func test_updateTaskShedulerLimit() {
        // Given
        let (session, _, attemptSheduler, _, _) = sessionObjects
        // When
        session.config.attemptsPerSecLimit = .limited(1)
        // Then
        XCTAssertEqual(attemptSheduler.limit.count, AttemptLimit.limited(1).count)
    }
    
    func test_updateConfig() {
        // Given
        let (session, _, attemptSheduler, _, _) = sessionObjects
        // When
        session.config = SessionConfig(attemptsPerSecLimit: .limited(1))
        // Then
        XCTAssertEqual(attemptSheduler.limit.count, AttemptLimit.limited(1).count)
    }
    
    func test_logIn_shouldBeSuccess() {
        // Given
        let (session, _, _, authorizator, repository) = sessionObjects
        let exp = expectation(description: "")
        // When
        swiftyVkDelegateMock.onVkLogInDidSuccess = { (givenGession, _) in
            XCTAssertEqual(givenGession.id, session.id)
            exp.fulfill()
        }
        
        session.logIn()
        // Then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(session.state, .authorized)
        XCTAssertEqual(authorizator.authorizeCallCount, 1)
        XCTAssertEqual(repository.saveCallCount, 1)
        XCTAssertEqual(repository.removeCallCount, 0)
    }
    
    func test_logIn_shouldBeFail_whenAuthorizatorThrows() {
        // Given
        let (session, _, _, authorizator, repository) = sessionObjects
        let exp = expectation(description: "")
        // When
        
        swiftyVkDelegateMock.onVkLogInDidFail = { (givenGession, error) in
            XCTAssertEqual(givenGession.id, session.id)
            XCTAssertEqual(error as? SessionError, .failedAuthorization)
            exp.fulfill()
        }
        
        authorizator.authorizeShouldThrows = true
        session.logIn()
        // Then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(session.state, .initiated)
        XCTAssertEqual(authorizator.authorizeCallCount, 1)
        XCTAssertEqual(repository.saveCallCount, 0)
        XCTAssertEqual(repository.removeCallCount, 0)
    }
    
    func test_logIn_shouldBeFail_whenSessionIsDead() {
        // Given
        let (session, _, _, _, _) = sessionObjects
        let exp = expectation(description: "")
        // When
        
        swiftyVkDelegateMock.onVkLogInDidFail = { (givenGession, error) in
            XCTAssertEqual(givenGession.id, session.id)
            XCTAssertEqual(error as? SessionError, .sessionIsDead)
            exp.fulfill()
        }
        
        session.die()
        session.logIn()
        // Then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(session.state, .dead)
    }
    
    func test_logInWithRawToken_shouldBeFail_whenSessionIsDead() {
        // Given
        let (session, _, _, _, _) = sessionObjects
        let exp = expectation(description: "")
        // When
        swiftyVkDelegateMock.onVkLogInDidFail = { (givenGession, error) in
            XCTAssertEqual(givenGession.id, session.id)
            XCTAssertEqual(error as? SessionError, .sessionIsDead)
            exp.fulfill()
        }
        
        session.die()
        session.logInWith(rawToken: "", expires: 0)
        // Then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(session.state, .dead)
    }
    
    func test_logIn_dhouldBeFail_whenDelegateNotFound() {
        // Given
        let (session, _, _, _, _) = sessionObjects
        // When
        VK.delegate = nil
        session.logIn()
        // Then
        XCTAssertEqual(session.state, .initiated)
    }
    
    func test_logInWithRepository() {
        // Given
        let (session, _, _, authorizator, repository) = sessionObjects
        // When
        repository.token = TokenMock()
        session.logIn()
        // Then
        XCTAssertEqual(session.state, .authorized)
        XCTAssertEqual(authorizator.authorizeCallCount, 0)
        XCTAssertEqual(repository.saveCallCount, 0)
        XCTAssertEqual(repository.removeCallCount, 0)
    }
    
    func test_logInWithRawToken() {
        // Given
        let (session, _, _, authorizator, _) = sessionObjects
        // When
        session.logInWith(rawToken: "", expires: 0)
        // Then
        XCTAssertEqual(session.state, .authorized)
        XCTAssertEqual(authorizator.authorizeWithRawTokenCallCount, 1)
    }
    
    func test_logOut() {
        // Given
        let (session, _, _, _, repository) = sessionObjects
        // When
        session.logInWith(rawToken: "", expires: 0)
        session.logOut()
        // Then
        XCTAssertEqual(session.state, .initiated)
        XCTAssertEqual(repository.removeCallCount, 1)
    }
    
    func test_logOut_withoutToken() {
        // Given
        let (session, _, _, _, repository) = sessionObjects
        // When
        session.logOut()
        // Then
        XCTAssertEqual(session.state, .initiated)
        XCTAssertEqual(repository.removeCallCount, 0)
    }
    
    func test_sendTask_whenSessionDead() {
        // Given
        let (session, _, _, _, _) = sessionObjects
        let request = Request(of: .url(""))
        // When
        session.id = ""

        session.send(
            request: request,
            callbacks: Callbacks(
                onError: { error in
                    // Then
                    XCTAssertEqual(error as? SessionError, .sessionIsDead)
            })
        )
    }
    
    func test_sendWrongTask() {
        // Given
        let (session, taskSheduler, _, _, _) = sessionObjects
        let request = Request(of: .url(""))
        // When
        taskSheduler.shouldThrows = true

        session.send(
            request: request,
            callbacks: Callbacks(
                onError: { error in
                    // Then
                    XCTAssertEqual(error as? RequestError, .wrongTaskType)
            })
        )
    }
    
    func test_sessionDie() {
        // Given
        let (session, _, _, _, _) = sessionObjects
        // When
        session.die()
        // Then
        XCTAssertEqual(session.state, .dead)
    }
}
