
@testable import Vapor
@testable import Fluent
@testable import HTTP
//import Turnstile

import XCTest



class TitanTests: XCTestCase {
    let drop = Droplet(arguments: ["dummy/path", "prepare"])
    var token: String = ""
    
    
    override func setUp() {
        
        drop.database = Database(MemoryDriver())
//        try! drop.database?.delete("users")
        try! load(drop)
        try! drop.runCommands()
        
        testRegisterUser()
        
        super.setUp()
    }
    
    func testRegisterUser() {
        let registerRequest  = try! Request(method: .post, uri: "/api/v1/users/register")
        registerRequest.headers = ["Content-Type" : "application/json"]
        registerRequest.body = JSON(["username" : "syky",
                                     "password" : "password"]).makeBody()
        
        let registerResponse = try! drop.respond(to: registerRequest)
        XCTAssertNotNil(registerResponse.json)
        if let token = registerResponse.json?["token"]?.string {
            self.token = token
        }
    }
    
    func patchSykyToAdmin() throws {
        let role = "admin"
        let patchReq = try Request(method: .patch, uri: "/api/v1/me")
        patchReq.headers = ["Content-Type" : "application/json",
                                "Authorization": "Bearer \(token)"]
        patchReq.body = JSON(["role" : role.makeNode()]).makeBody()
        
        let patchRes = try drop.respond(to: patchReq)
        print(patchRes)
        XCTAssertEqual(200, patchRes.status.hashValue)
        XCTAssertEqual(role, patchRes.json?["role"]?.string)
        
        
    }
    
    func testGetUsers() throws {
        try patchSykyToAdmin()
        let usersRequest  = try Request(method: .get, uri: "/api/v1/users")
        usersRequest.headers = ["Content-Type" : "application/json",
                                "Authorization": "Bearer \(token)"]
        
        
        let userResponse = try drop.respond(to: usersRequest)
        XCTAssertNotNil(userResponse.json)
        
        
        XCTAssertEqual(200, userResponse.status.hashValue)
    }
    
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
}

