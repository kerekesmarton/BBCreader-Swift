//
//  Communication.swift
//  Reader
//
//  Created by Kerekes Jozsef-Marton on 14/09/16.
//  Copyright © 2016 mkerekes. All rights reserved.
//

import Foundation

enum CommunicationError : Error {
    
    case Network
    case Service
    case Parsing
    case NotFound
    case Other (String)
}

enum Result<T> {
    case Success(T)
    case Failure(Error)
}

extension Result {
    
    func test() -> Bool {
        
        switch self {
        case Result.Success:
            return true
        default:
            return false
        }
    }
        
    // Return the value if it's a .Success or throw the error if it's a .Failure
    func resolve() throws -> T {
        switch self {
        case Result.Success(let value): return value
        case Result.Failure(let error): throw error
        }
    }
    
    // Construct a .Success if the expression returns a value or a .Failure if it throws
    init( _ throwingExpression: (Void) throws -> T) {
        do {
            let value = try throwingExpression()
            self = Result.Success(value)
        } catch {
            self = Result.Failure(error)
        }
    }
}

struct ServerCommunication  {
    
    private let callGateway = "http://www.bbc.co.uk"
    private let downloadGateway = "http://ichef.bbci.co.uk"
    private let session : URLSession = URLSession.shared
    
    func callWithService(_ service: String, completion: @escaping (Result<Data>) -> Void) {
        
        let path : URL = URL.init(string: callGateway)!.appendingPathComponent(service)
        
        session.dataTask(with: path, completionHandler: { (data, response, error) in
            
            completion(Result {
                if let error = error { throw CommunicationError.Other(error.localizedDescription) }
                if let response = response as? HTTPURLResponse {
                    if (response.statusCode != 200) { throw CommunicationError.Other(HTTPURLResponse.localizedString(forStatusCode: response.statusCode)) }
                }
                guard let data = data else { throw CommunicationError.NotFound }
                return data
            })
            
        }).resume()
    }
    
    func downloadWithService(_ service: String, completion: @escaping (Result<URL>) -> Void) {
        
        let path : URL = URL.init(string: downloadGateway)!.appendingPathComponent(service)
        
        session.downloadTask(with: path, completionHandler: { (url, response, error) in
            
            completion(Result {
                if let error = error { throw CommunicationError.Other(error.localizedDescription) }
                if let response = response as? HTTPURLResponse {
                    if (response.statusCode != 200) { throw CommunicationError.Other(HTTPURLResponse.localizedString(forStatusCode: response.statusCode)) }
                }
                guard let url = url else { throw CommunicationError.NotFound }
                return url
            })
            
        }).resume()
    }
}





