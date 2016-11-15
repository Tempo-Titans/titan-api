
@testable import Vapor
@testable import Fluent
@testable import HTTP
//import Turnstile

import XCTest



class HelloWorldTests: XCTestCase {
    let drop = Droplet(arguments: ["dummy/path", "prepare"])
    var token: String = ""
    
    override func setUp() {
        drop.database = Database(MemoryDriver())
        try! load(drop)
        try! drop.runCommands()
        
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRegister() throws {
        
        let registerRequest  = try Request(method: .post, uri: "/api/v1/users/register")
        registerRequest.headers = ["Content-Type" : "application/json"]
        registerRequest.body = JSON(["username" : "syky",
                                     "password" : "password"]).makeBody()
        let registerResponse = try drop.respond(to: registerRequest)
        XCTAssertNotNil(registerResponse.json?["token"]?.string)
        token = (registerResponse.json?["token"]?.string)!
        
        XCTAssertEqual(200, registerResponse.status.hashValue)
        
    }
    
//    func testLogin() throws {
//        let loginRequest
//    }
    
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

