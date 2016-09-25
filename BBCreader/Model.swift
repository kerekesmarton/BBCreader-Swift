//
//  Model.swift
//  Reader
//
//  Created by Kerekes Jozsef-Marton on 13/09/16.
//  Copyright © 2016 mkerekes. All rights reserved.
//

import UIKit

let UNKNOWN_FORMAT_EXCEPTION = "Unknown format encountered"

typealias JSONDict = Dictionary<String,Any>


fileprivate let _dateFormatter = DateFormatter()
fileprivate var dateFormatter: DateFormatter {
    
    _dateFormatter.dateFormat = "yyyy-MM-dd"
    return  _dateFormatter
}

fileprivate var dateTimeFormatter: DateFormatter {
    
    _dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
    return  _dateFormatter
}

fileprivate var relativeDateFormatter: DateFormatter {
    
    _dateFormatter.dateStyle = .short
    _dateFormatter.doesRelativeDateFormatting = true
    return  _dateFormatter
}

fileprivate var timeFormatter: DateFormatter {
    
    _dateFormatter.timeStyle = .short
    return  _dateFormatter
}

struct Parser {
    
    static func parse(_ data: Any?) throws -> Model {
        
        if data is Dictionary <String,Any> {
            
            var results : Array = Array<Model>()
            
            for (key, obj) in data as! Dictionary <String,Any> {
                
                do {
                 
                    let model = try modelForKey(key:key, objects:obj as! JSONDict)
                    results.append(model)
                } catch let error {
                    print(error.localizedDescription)
                }
            }
            
            // Looking at the HTTP response, there is always only one schedule object per day, assuming as such. In case the API changes, this has to be changed.
            return results.first!
        }
        else
        {
            throw CommunicationError.Parsing
        }
    }
    
    fileprivate static func modelForKey(key : String, objects: JSONDict) throws -> Model {
        
        var result : Model?
        
        switch key {
        case "schedule":
            result = Schedule(objects)
        case "day":
            result = Day(objects)
        case "broadcast":
            result = Broadcast(objects)
        case "programme":
            result = Programme(objects)
        case "image":
            result = Image(objects)
        case "displayTitle":
            result = DisplayTitles(objects)
        default:
            throw CommunicationError.Other("Data type not recognized")
        }
        
        return result!
    }
}

protocol Displayable {
    
    func text() -> String
}

protocol Model {
    
}

protocol JSONConstructable {
    init(_ data: JSONDict)
}

struct ErrorModel : Model,Displayable {
    
    var error : Error? = nil
    
    init(_ error : Error) {
        self.error = error
    }
    
    func text() -> String {
        
        return error?.localizedDescription ?? "Some error occured"
    }
}

struct Schedule : Model,JSONConstructable,Displayable {
    
    var day : Day
    init(_ data: JSONDict) {
        
        day = Day(data["day"] as! JSONDict)
    }
    
    internal func text() -> String {
        return day.dayReadable()!
    }

}

struct Day : Model,JSONConstructable{
    var date : Date
    var broadcasts : Array <Broadcast>
    
    init(_ data: JSONDict) {
        
        date = Date()
        
        if let string = data["date"] as? String {
            date = dateFormatter.date(from: string)!
        }
        
        broadcasts = Broadcast.broadcastsFormArray(data["broadcasts"] as! Array<JSONDict>)
        
    }
    func dayReadable() -> String? {
        return relativeDateFormatter.string(from: date)
    }
}

struct Broadcast : Model,JSONConstructable {
    
    var start : Date
    var end : Date
    let duration : TimeInterval
    let programme : Programme
    
    init(_ data: JSONDict) {
        start = Date()
        if let string = data["start"] as? String {
            start = dateTimeFormatter.date(from: string)!
        }
        end = Date()
        if let string = data["end"] as? String {
            end = dateTimeFormatter.date(from: string)!
        }
        
        duration = TimeInterval(data["duration"] as! Int)
        programme = Programme(data["programme"] as! JSONDict)
    }
    
    func meta() -> String? {
        return nil
    }
    
    static func broadcastsFormArray(_ array : Array<JSONDict>) -> Array<Broadcast> {
        
        var results : Array<Broadcast> = Array()
        for obj in array {
            results.append(Broadcast(obj))
        }
        return results
    }
}

struct Programme : Model,JSONConstructable {
    
    let image : Image
    let displayTitles: DisplayTitles
    
    init(_ data: JSONDict) {
        image = Image(data["image"] as! JSONDict)
        
        displayTitles =  DisplayTitles(data["display_titles"] as! JSONDict)
    }
    
    func imageTitle() -> String? {
        return nil
    }
    
    func programmeTitle() -> String? {
        return nil
    }
}

struct Image : Model,JSONConstructable {
    let pid : String
    
    init(_ data : JSONDict) {
        pid = data["pid"] as! String
    }
}

struct DisplayTitles : Model,JSONConstructable {
    let title : String
    let subTitle : String
    
    init(_ data : JSONDict) {
        title = data["title"] as! String
        subTitle = data["subtitle"] as! String
    }
}

