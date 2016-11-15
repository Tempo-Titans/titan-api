
@testable import Vapor
@testable import Fluent
@testable import HTTP
//import Turnstile

import XCTest



class HelloWorldTests: XCTestCase {
    
    
//    override func setUp() {
//       
//
//        
//        super.setUp()
//        
//        
//    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() throws {
//        do {
        let drop = Droplet()
        drop.database = Database(MemoryDriver())
//        try drop.runCommands()
        
        try load(drop)
        
        let registerRequest  = try Request(method: .post, uri: "/api/v1/users/register")
        registerRequest.headers = ["Content-Type" : "application/json"]
        registerRequest.body = JSON(["username" : "username",
                                     "password" : "password"]).makeBody()
        let registerResponse = try drop.respond(to: registerRequest)
        
        XCTAssertEqual(200, registerResponse.status.hashValue)
        
        print(registerResponse)
//        } catch let e {
//            print(e)
//        }
        
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

