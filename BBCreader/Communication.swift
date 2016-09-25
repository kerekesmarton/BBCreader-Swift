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
                if let HTTPResponse = response as? HTTPURLResponse {
                    if (HTTPResponse.statusCode != 200) { throw CommunicationError.NotFound }
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
                if let HTTPResponse = response as? HTTPURLResponse {
                    if (HTTPResponse.statusCode != 200) { throw CommunicationError.NotFound }
                }
                guard let url = url else { throw CommunicationError.NotFound }
                return url
            })
            
        }).resume()
    }
}

struct ProgrammeService {
    
    private let tomorrow = "tomorrow.json"
    private let today = "today.json"
    private let yesterday = "yesterday.json"
    private let serviceLocation = "/radio4/programmes/schedules/fm/"
    private let communication : ServerCommunication = ServerCommunication()
    
    func fetchProgramme(_ completion: @escaping (Result<Array<Model>>) -> Void) {
        
        DispatchQueue.global().async {
            
            let group : DispatchGroup = DispatchGroup();
            var resultArray : Array<Model> = Array()
            
            group.enter();
            
            let todayServicePath = self.serviceLocation.appendingFormat("/%@", self.today)
            
            self.communication.callWithService(todayServicePath, completion: { (resultData : Result<Data>) in
               
                do {
                    let result = try JSONSerialization.jsonObject(with: resultData.resolve(), options:.allowFragments)
                    let object = try Parser.parse(result)
                    resultArray.append(object)
                } catch let error {
                    resultArray.append(ErrorModel(error))
                }
                
                group.leave();
                
            })
            group.enter();
            
            let yesterdayServicePath = self.serviceLocation.appendingFormat("/%@", self.yesterday)
            self.communication.callWithService(yesterdayServicePath, completion: { (resultData : Result<Data>) in
                
                do {
                    let result = try JSONSerialization.jsonObject(with: resultData.resolve(), options:.allowFragments)
                    let object = try Parser.parse(result)
                    resultArray.append(object)
                } catch let error {
                    resultArray.append(ErrorModel(error))
                }
                group.leave();
            })
            
            group.enter();
            
            let tomorrowServicePath = self.serviceLocation.appendingFormat("/%@", self.tomorrow)
            self.communication.callWithService(tomorrowServicePath, completion: { (resultData : Result<Data>) in
                
                do {
                    let result = try JSONSerialization.jsonObject(with: resultData.resolve(), options:.allowFragments)
                    let object = try Parser.parse(result)
                    resultArray.append(object)
                } catch let error {
                    resultArray.append(ErrorModel(error))
                }
                group.leave();
            })

            group.notify(queue: DispatchQueue.main, execute: {
                completion(
                    Result {
                    
                        for model : Model in resultArray
                        {
                            if model is ErrorModel { throw CommunicationError.Parsing }
                        }
                        
                        return resultArray
                
                    }
                )
            });
        }
    }
    
    func fetchToday(_ completion: @escaping (Result<Model>) -> Void) {
        
        let todayServicePath = serviceLocation.appendingFormat("/%@", self.today)
        self.communication.callWithService(todayServicePath, completion: { (resultData : Result<Data>) in
            
            do {
                let result = try JSONSerialization.jsonObject(with: resultData.resolve(), options:.allowFragments)
                let object = try Parser.parse(result)
                
                DispatchQueue.main.async {
                    completion(
                        Result {
                            if object is ErrorModel { throw CommunicationError.Parsing }
                            return object
                        }
                    )
                }
            } catch _ {}
            
        })
    }
}

fileprivate var imageCache : Dictionary <String, Data> = Dictionary()

struct ImageService {
    
    private let communication : ServerCommunication = ServerCommunication()
    private let serviceLocation = "images/ic";
    private let imageSize = "480x270";
    
    func fetchImage(pid: String, completion: @escaping (_ data: Any?) -> Void) {
    
        var data = imageCache[pid]!
        
        if data.count > 0
        {
            completion(data)
        }
        
        let servicePath : String = serviceLocation.appendingFormat("/%@/%@.jpg", imageSize, pid)
        
        communication.downloadWithService(servicePath, completion: { (resultUrl : Result<URL>) in
            
            do {
                let imageData = try Data(contentsOf: resultUrl.resolve(), options:[])
                imageCache[pid] = imageData
                completion(imageData)
            }
            catch let error as NSError {
                print(error)
            }
        })
    }
}





