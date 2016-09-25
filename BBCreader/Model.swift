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

enum JSON {
    
    case Model(JSONDict?)
    case Error(Error)
    
    func parse() throws -> Model {
        switch self {
        case JSON.Model(let json): return Day.itemsFromJSONData(json)
        case JSON.Error(let error): return ErrorModel(error)
        }
    }
    
    init(_ data: Any?) {
        
        switch data {
        case is JSONDict:
            self = JSON.Model(data as? JSONDict)
        case is Error:
            self = JSON.Error((data as? Error)!)
        default:
            self = JSON.Error(CommunicationError.Parsing)
        }
    }
}

protocol Model {
    func text() -> String
}

protocol JSONConstructable {
    
    static func itemsFromJSONData(_ : JSONDict?) -> Model
}

struct ErrorModel : Model {
    
    var error : Error? = nil
    
    init(_ error : Error) {
        self.error = error
    }
    
    func text() -> String {
        
        return error?.localizedDescription ?? "Some error occured"
    }
}

struct Day : JSONConstructable, Model{
    
    var date : Date? = nil
    var broadcasts : Array <Broadcast>? = Array()
    
    internal static func itemsFromJSONData(_ json: JSONDict?) -> Model {
        
        var day : Day = Day()
        
        let dayfragment = json.flatMap {$0["schedule"] as? JSONDict}.flatMap{$0["day"] as? JSONDict}
        
        guard let string = dayfragment?["date"] as? String,
            let jsonArray : Array<JSONDict> = dayfragment?["broadcasts"] as? Array<JSONDict>
            else {
            return day
        }
        
        day.date = dateFormatter.date(from: string)!
        
        for jsonItem : JSONDict in jsonArray {
            let broadcast = Broadcast.itemsFromJSONData(jsonItem)
            day.broadcasts?.append(broadcast as! Broadcast)
        }
        
        return day
    }
    
    internal func text() -> String {
        guard let date = date else {
            return ""
        }
        return relativeDateFormatter.string(from: date)
    }
}

struct Broadcast : JSONConstructable, Model {
    
    var start : Date? = nil
    var end : Date? = nil
    var duration : TimeInterval? = nil
    var imagePid : String? = nil
    var title: String? = nil
    var subTitle : String? = nil
    
    
    internal static func itemsFromJSONData(_ json: JSONDict?) -> Model {
        
        var broadcast = Broadcast()
        
        let programmeFragment = json.flatMap{$0["programme"] as? JSONDict}
        let imageFragment = programmeFragment.flatMap{$0["image"] as? JSONDict}
        let titlesFragment = programmeFragment.flatMap{$0["display_titles"] as? JSONDict}
        
        guard let start : String = json?["start"] as? String,
            let end : String = json?["end"] as? String,
            let duration = json?["duration"] as? Int,
            let imagePid = imageFragment?["pid"] as? String,
            let title = titlesFragment?["title"] as? String,
            let subtitle = titlesFragment?["subtitle"] as? String
        
        else {
            return broadcast
        }
        
        broadcast.start = dateTimeFormatter.date(from: start)!
        broadcast.end = dateTimeFormatter.date(from: end)!
        broadcast.duration = TimeInterval(duration)
        broadcast.imagePid = imagePid
        broadcast.title = title
        broadcast.subTitle = subtitle

        
        return Broadcast()
    }
    
    internal func text() -> String {
        return meta()
    }
    
    func meta() -> String {
        
        guard let start = start,
            let end = end,
            let duration = duration
        else {
            return ""
        }
        
        return "Start:" + relativeDateFormatter.string(from:start) + "\nEnd:" + relativeDateFormatter.string(from: end) + "\nDuration:" + String(duration)
    }
    
    func imageTitle() -> String {
        guard let str = imagePid else {
            return ""
        }
        return str
    }
    
    func programmeTitle() -> String? {
        guard let str = title else {
            return ""
        }
        return str
    }
}


