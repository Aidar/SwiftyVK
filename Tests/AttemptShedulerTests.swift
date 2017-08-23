import XCTest
@testable import SwiftyVK

final class AttemptShedulerTests: XCTestCase {
    
    let shedulerLimit = AttemptLimit.limited(30)
    let count = 100
    var totalDelay: TimeInterval {
        return AttemptMock().delay*Double(count)
    }
    
    func test_concurrentShedule() {
        // Given
        let sheduler = AttemptShedulerImpl(limit: shedulerLimit)
        let samples = (0..<count).map { _ in AttemptMock() }
        
        // When
        samples.forEach { try! sheduler.shedule(attempt: $0, concurrent: true) }
        
        // Then
        Thread.sleep(forTimeInterval: totalDelay/10)
        
        XCTAssertEqual(
            samples.map {$0.isFinished},
            (0..<count).map { _ in true },
            "All concurrent operations should be executed"
        )
    }
    
    func test_serialShedule() {
        // Given
        let sheduler = AttemptShedulerImpl(limit: shedulerLimit)
        let samples = (0..<count).map { _ in AttemptMock() }
        
        // When
        samples.forEach { try! sheduler.shedule(attempt: $0, concurrent: false) }
        
        // Then
        Thread.sleep(forTimeInterval: 1)
        
        XCTAssertLessThan(
            samples.filter { $0.isFinished }.count,
            shedulerLimit.count*2,
            "Operations should be executed serially"
        )
        
        Thread.sleep(forTimeInterval: Double(count/shedulerLimit.count*2))
        
        XCTAssertEqual(
            samples.filter { $0.isFinished }.count,
            count,
            "All operations should be executed"
        )
    }
    
    func test_randomShedule() {
        // Given
        let sheduler = AttemptShedulerImpl(limit: shedulerLimit)
        let serial = (0..<count).map { _ in AttemptMock() }
        let concurrent = (0..<count).map { _ in AttemptMock() }
        let samples = serial.map { ($0, false) } + concurrent.map { ($0, true) }
        
        // When
        samples.forEach { try! sheduler.shedule(attempt: $0.0, concurrent: $0.1) }
        
        // Then
        Thread.sleep(forTimeInterval: 1)
        
        XCTAssertLessThan(
            serial.filter { $0.isFinished }.count,
            shedulerLimit.count*2,
            "Operations should be executed serially"
        )
        
        XCTAssertEqual(concurrent.map {$0.isFinished}, (0..<count).map { _ in true },
            "All concurrent operations should be executed"
        )
        
        Thread.sleep(forTimeInterval: Double(count/shedulerLimit.count*2))
        
        XCTAssertEqual(serial.filter { $0.isFinished }.count, count,
            "All serial operations should be executed"
        )
    }
    
    func test_wrongShedule() {
        // Given
        let sheduler = AttemptShedulerImpl(limit: shedulerLimit)
        let sample = WrongAttemptMock()
        
        do {
            // When
            try sheduler.shedule(attempt: sample, concurrent: false)
            XCTFail("Wrong attempt should cause exception")
        } catch let error {
            // Then
            XCTAssertEqual(error.asVk, VkError.wrongAttemptType)
        }
    }
    
    func test_setLimit() {
        // Given
        let sheduler = AttemptShedulerImpl(limit: .unlimited)
        let samples = (0..<count).map { _ in AttemptMock() }
        
        // When
        sheduler.setLimit(to: .limited(1))
        samples.forEach { try! sheduler.shedule(attempt: $0, concurrent: false) }
        
        // Then
        Thread.sleep(forTimeInterval: 1)
        
        XCTAssertEqual(
            samples.filter { $0.isFinished } .count,
            1,
            "Only one operation should be executed"
        )
    }
}
