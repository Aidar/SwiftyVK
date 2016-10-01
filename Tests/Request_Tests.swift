import XCTest
@testable import SwiftyVK


class Sending_Tests: VKTestCase {
    
    
    
    func test_get_method() {
        Stubs.apiWith(params: ["user_ids":"1"], httpMethod: .GET, jsonFile: "success.users.get")
        let exp = expectation(description: "ready")
        
        let req = VK.API.Users.get([VK.Arg.userIDs : "1"])
        req.asynchronous = true
        
        req.successBlock = {response in
            XCTAssertEqual(response[0,"id"].int, 1)
            exp.fulfill()
        }
        
        req.errorBlock = {error in
            XCTFail("Unexpected error: \(error)")
            exp.fulfill()
        }
        
        req.send(method: .GET)
        waitForExpectations(timeout: reqTimeout) {_ in}
    }
    
    
    
    func test_post_method() {
        Stubs.apiWith(params: ["user_ids":"1"], httpMethod: .POST, jsonFile: "success.users.get")
        let exp = expectation(description: "ready")
        
        let req = VK.API.Users.get([VK.Arg.userIDs : "1"])
        req.asynchronous = true
        
        req.successBlock = {response in
            XCTAssertEqual(response[0,"id"].int, 1)
            exp.fulfill()
        }
        
        req.errorBlock = {error in
            XCTFail("Unexpected error: \(error)")
            exp.fulfill()
        }
        
        req.send(method: .POST)
        waitForExpectations(timeout: reqTimeout) {_ in}
    }
    
    
    
    func test_succes_block_memory_leak() {
        Stubs.apiWith(jsonFile: "success.users.get")
        let exp = expectation(description: "ready")
        
        var strongObject: NSObject? = NSObject()
        weak var weakObject: NSObject? = strongObject
        
        let req = VK.API.Users.get([VK.Arg.userIDs : "a"])
        req.asynchronous = true
        
        req.successBlock = {response in
            let _ = strongObject?.description
            exp.fulfill()
        }
        
        strongObject = nil
        req.send()
        
        waitForExpectations(timeout: reqTimeout) {_ in
            XCTAssertNil(weakObject, "Test object did not released")
        }
    }
    
    
    
    func test_error_block_memory_leak() {
        Stubs.apiWith(jsonFile: "error.missing.parameter")
        let exp = expectation(description: "ready")
        
        var strongObject: NSObject? = NSObject()
        weak var weakObject: NSObject? = strongObject
        
        let req = VK.API.Users.get([VK.Arg.userIDs : "a"])
        req.asynchronous = true

        req.errorBlock = {error in
            let _ = strongObject?.description
            exp.fulfill()
        }
        
        strongObject = nil
        req.send()
        
        waitForExpectations(timeout: reqTimeout) {_ in
            XCTAssertNil(weakObject, "Test object did not released")
        }
    }
    
    
    
    func test_waiting_for_connection() {
        Stubs.apiWith(jsonFile: "success.users.get", shouldFails: 10)
        let exp = expectation(description: "ready")
        
        let req = VK.API.Users.get([VK.Arg.userIDs : "1"])
        req.maxAttempts = 0
        req.successBlock = {response in
            exp.fulfill()
        }
        
        req.errorBlock = {error in
            XCTFail("Unexpected error: \(error)")
            exp.fulfill()
        }
        
        req.send()
        waitForExpectations(timeout: reqTimeout*10) {_ in}
    }
    
    
    
    func test_executing_error_block() {
        Stubs.apiWith(method: "groups.isMember", jsonFile: "error.missing.parameter", maxCalls: VK.defaults.maxAttempts)
        let exp = expectation(description: "ready")
        
        let req = VK.API.Groups.isMember()
        
        req.successBlock = {response in
            XCTFail("Unexpected response: \(response)")
            exp.fulfill()
        }
        
        req.errorBlock = {error in
            XCTAssertEqual(error.domain, "APIDomain")
            XCTAssertEqual(error.code, 100)
            exp.fulfill()
        }
        
        req.send()
        waitForExpectations(timeout: reqTimeout) {_ in}
    }
    
    
    
    func test_synchroniously() {
        Stubs.apiWith(jsonFile: "success.users.get", maxCalls: 10)
        let exp = expectation(description: "ready")
        
        DispatchQueue.global(qos: .userInitiated).async {
            for n in 1...10 {
                let req = VK.API.Users.get([VK.Arg.userIDs : "\(n)"])
                req.asynchronous = false
                var executed = false
                
                req.send(
                    onSuccess: {response in
                        executed = true
                    },
                    onError: {error in
                        executed = true
                        XCTFail("\(n) call has unexpected error: \(error)")
                        exp.fulfill()
                })
                
                XCTAssertTrue(executed, "Request \(n) is not synchronious")
                n == 10 ? exp.fulfill() : ()
            }
        }
        
        waitForExpectations(timeout: reqTimeout*10) {_ in}
    }
    
    
    
    func test_asynchroniously() {
        Stubs.apiWith(jsonFile: "success.users.get", maxCalls: 10)
        let exp = expectation(description: "ready")
        var exeCount = 0
        
        for n in 1...10 {
            let req = VK.API.Users.get([VK.Arg.userIDs : "\(n)"])
            req.asynchronous = true
            req.send(
                onSuccess: {response in
                    exeCount += 1
                    exeCount >= 10 ? exp.fulfill() : ()
                },
                onError: {error in
                    XCTFail("\(n) call has unexpected error: \(error)")
                    exp.fulfill()
            })
        }
        
        waitForExpectations(timeout: reqTimeout*10) {_ in}
    }
    
    
    
    func test_randomly() {
        Stubs.apiWith(jsonFile: "success.users.get")
        let backup = VK.defaults.sendLimit
        VK.defaults.sendLimit = 100
        let exp = self.expectation(description: "ready")
        let requests = NSMutableDictionary()
        var executed = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            for n in 1...VK.defaults.sendLimit {
                let req = VK.API.Users.get([VK.Arg.userIDs : "\(n)"])
                requests[req.id] = "~"
                req.asynchronous = n%3 != 0
                
                req.send(
                    onSuccess: {response in
                        requests[req.id] = "+"
                        executed += 1
                        executed >= VK.defaults.sendLimit ? exp.fulfill() : ()
                    },
                    onError: {error in
                        requests[req.id] = "-"
                        executed += 1
                        executed >= VK.defaults.sendLimit ? exp.fulfill() : ()
                })
            }
        }
        
        self.waitForExpectations(timeout: reqTimeout*20) {_ in
            VK.defaults.sendLimit = backup
            let results = self.getResults(requests)
            printSync(results.statistic)
            XCTAssertGreaterThan(results.all.count/50, results.error.count, "Too many errors")
            XCTAssertTrue(results.unused.isEmpty, "\(results.unused.count) requests was not send")
        }
    }
    
    
    
    func test_performance() {
        measure() {
            Stubs.apiWith(jsonFile: "success.users.get")
            let exp = self.expectation(description: "ready")
            var executed = 0
            
            for n in 1...VK.defaults.sendLimit {
                let req = VK.API.Users.get([VK.Arg.userIDs : "\(n)"])
                req.asynchronous = true
                req.send(
                    onSuccess: {response in
                        executed += 1
                        executed == VK.defaults.sendLimit ? exp.fulfill() : ()
                    },
                    onError: {error in
                        executed += 1
                        executed == VK.defaults.sendLimit ? exp.fulfill() : ()
                })
            }
            
            self.waitForExpectations(timeout: self.reqTimeout*Double(VK.defaults.sendLimit)) {_ in}
        }
    }
}
