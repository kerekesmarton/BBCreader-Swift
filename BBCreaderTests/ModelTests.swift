//
//  ModelTests.swift
//  BBCreader
//
//  Created by Kerekes Jozsef-Marton on 21/09/16.
//  Copyright © 2016 mkerekes. All rights reserved.
//

import XCTest

class ModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testParser_parse() {
        
        let url = Bundle.main.url(forResource: "today", withExtension: "json")
        var data : Data? = nil
        var json : Any? = nil
        do {
            data = try Data.init(contentsOf: url!)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
                
        do {
            json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
        
        do {
            let result : Model = try Parser.parse(json)
            XCTAssertNotNil(result)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
        
        
    }
    
    
    
}
