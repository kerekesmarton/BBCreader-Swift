//
//  CommunicationTests.swift
//  BBCreader
//
//  Created by Kerekes Jozsef-Marton on 21/09/16.
//  Copyright © 2016 mkerekes. All rights reserved.
//

import XCTest

class CommunicationTests: XCTestCase {
    
    var communicator : ServerCommunication!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        communicator = ServerCommunication()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCallWithService() {
        
        //Arrange
        let servicePath = "/radio4/programmes/schedules/fm/today.json"
        let expectation : XCTestExpectation = self.expectation(description: "testCallWithService")
        
        //Act
        communicator.callWithService(servicePath) { (resultData : Result<Data>) in
        
            //Assert             
            XCTAssert(resultData.test())
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10) {error in
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testDownloadWithService_correctPID() {
        
        //Arrange
        let servicePath : String = "images/ic/480x270/p01lcbf6.jpg"
        let expectation : XCTestExpectation = self.expectation(description: "testDownloadWithService")
        
        //Act
        communicator.downloadWithService(servicePath) { (resultURL : Result<URL>) in
            
            //Assert
            XCTAssert(resultURL.test())
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10) { error in
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testDownloadWithService_badPID() {
        
        //Arrange
        let servicePath : String = "images/ic/480x270/wrong.jpg"
        let expectation : XCTestExpectation = self.expectation(description: "testDownloadWithService")
        
        //Act
        communicator.downloadWithService(servicePath) { (resultURL : Result<URL>) in
            
            //Assert
            XCTAssertFalse(resultURL.test())
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10) { error in
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func test_ProgramService_fetchProgramme() {
        
        let service : ProgrammeService = ProgrammeService()
        let expectation : XCTestExpectation = self.expectation(description: "test_ProgramService_fetchProgramme")
        service.fetchProgramme { (result : Result<Array<Model>>) in
            
            XCTAssert(result.test())
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10) { (error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    
    func test_ProgrammeService_fetchToday() -> Void {
        
        let service : ProgrammeService = ProgrammeService()
        let expectation : XCTestExpectation = self.expectation(description: "test_ProgrammeService_fetchToday")
        
        service.fetchToday { (result : Result<Model>) in
            
            XCTAssert(result.test())
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10) { (error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}















