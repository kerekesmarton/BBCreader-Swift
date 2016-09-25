//
//  Service.swift
//  BBCreader
//
//  Created by Kerekes Jozsef-Marton on 25/09/16.
//  Copyright © 2016 mkerekes. All rights reserved.
//

import Foundation


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
                    let object = try JSON(result).parse()
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
                    let object = try JSON(result).parse()
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
                    let object = try JSON(result).parse()
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
                let object = try JSON(result).parse()
                
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
