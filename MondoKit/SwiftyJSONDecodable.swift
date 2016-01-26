//
//  SwiftyJSONDecodable.swift
//  MondoKit
//
//  Created by Mike Pollard on 21/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//


import Foundation
import SwiftyJSON

public protocol SwiftyJSONDecodable {
    
    init(json: JSON) throws
    
}

indirect enum SwiftyJSONDecodeError : ErrorType {
    
    case NullValue
    case WrongType
    case InvalidValue(String?)
    case ErrorForKey(key: String, error: SwiftyJSONDecodeError)
}

extension SwiftyJSONDecodeError : CustomDebugStringConvertible {
    
    var debugDescription: String {
        switch self {
        case NullValue : return "NullValue"
        case WrongType : return "WrongType"
        case InvalidValue(let s) : return "InvalidValue(" + (s ?? "nil") + ")"
        case ErrorForKey(let key, let error) :
            return key + "." + error.debugDescription
        }
    }
}

extension Int : SwiftyJSONDecodable {
    
    public init(json: JSON) throws {
        guard json != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        guard let i = json.int else { throw SwiftyJSONDecodeError.WrongType }
        self.init(i)
    }
}

extension Double : SwiftyJSONDecodable {
    
    public init(json: JSON) throws {
        guard json != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        guard let d = json.double else { throw SwiftyJSONDecodeError.WrongType }
        self.init(d)
    }
}

extension String : SwiftyJSONDecodable {
  
    public init(json: JSON) throws {
        guard json != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        guard let s = json.string else { throw SwiftyJSONDecodeError.WrongType }
        self.init(s)
    }
}

extension Bool : SwiftyJSONDecodable {
    
    public init(json :JSON) throws {
        guard json != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        guard let b = json.bool else { throw SwiftyJSONDecodeError.WrongType }
        self.init(b)
    }
}

extension JSON {
    
    func decodeAsArray<T: SwiftyJSONDecodable>(onDecodeElement onDecodeElement:((elementWasDecoded: T, fromJSON: JSON) throws ->())? = nil) throws -> Array<T> {
    
        guard self != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        
        guard let arrayJSON = self.array else { throw SwiftyJSONDecodeError.WrongType }
        
        var elements = [T]()
        for elementJson in arrayJSON {
            let element = try T(json: elementJson)
            elements.append(element)
        }
        
        for (element,elementJson) in zip(elements, arrayJSON) {
            try onDecodeElement?(elementWasDecoded: element, fromJSON: elementJson)
        }
        
        return elements
    }
    
    func decodeArrayForKey<T: SwiftyJSONDecodable>(key: String, onDecodeElement:((elementWasDecoded: T, fromJSON: JSON) throws ->())? = nil) throws -> Array<T> {
        
        guard let _ = self.dictionary else { throw SwiftyJSONDecodeError.WrongType }
        
        do {
            let json = self[key]
            return try json.decodeAsArray(onDecodeElement: onDecodeElement)
        }
        catch let error as SwiftyJSONDecodeError {
            throw SwiftyJSONDecodeError.ErrorForKey(key: key, error: error)
        }
    }
    
    func decodeValueForKey<T: SwiftyJSONDecodable>(key: String) throws -> T {
        
        guard let _ = self.dictionary else { throw SwiftyJSONDecodeError.WrongType }
        
        do {
            let json = self[key]
            return try json.decodeAsValue()
        }
        catch let error as SwiftyJSONDecodeError {
            throw SwiftyJSONDecodeError.ErrorForKey(key: key, error: error)
        }
    }
    
    func decodeAsValue<T: SwiftyJSONDecodable>() throws -> T {
        
        guard self != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        
        return try T(json: self)
    }

    func decodeAsDictionary<V: SwiftyJSONDecodable>(onDecodeElement onDecodeElement:((elementWasDecoded: V, fromJSON: JSON) throws ->())? = nil) throws -> Dictionary<String, V> {
        
        guard self != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        
        guard let dictJSON = self.dictionary else { throw SwiftyJSONDecodeError.WrongType }
        
        var result = [String:V]()
        for (k, j) in dictJSON {
            let v : V = try j.decodeAsValue()
            result[k] = v
        }
        
        return result
    }
    
    func decodeAsDictionaryForKey<V: SwiftyJSONDecodable>(key: String, onDecodeElement:((elementWasDecoded: V, fromJSON: JSON) throws ->())? = nil) throws -> Dictionary<String, V> {
        
        do {
            let json = self[key]
            return try json.decodeAsDictionary(onDecodeElement: onDecodeElement)
        }
        catch let error as SwiftyJSONDecodeError {
            throw SwiftyJSONDecodeError.ErrorForKey(key: key, error: error)
        }
    }
}

extension SwiftyJSONDecodable where Self : RawRepresentable, Self.RawValue : SwiftyJSONDecodable {
    
    public init(json: JSON) throws {
        guard json != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        guard let rawValue = json.rawValue as? Self.RawValue else { throw SwiftyJSONDecodeError.WrongType }
        if let _ = Self(rawValue: rawValue) {
            self.init(rawValue: rawValue)!
        }
        else {
            throw SwiftyJSONDecodeError.InvalidValue(json.rawString())
        }
    }
    
}

extension NSDate {
    
    var toJsonDateTime : String {
        return JSONDate.dateFormatterNoMillis.stringFromDate(self)
    }
}

final class JSONDate : NSDate, SwiftyJSONDecodable {
    
    static var dateFormatter : NSDateFormatter = {
    
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        return formatter
    }()
    
    static var dateFormatterNoMillis : NSDateFormatter = {
        
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        return formatter
    }()
    
    private var _timeIntervalSinceReferenceDate : NSTimeInterval
    override var timeIntervalSinceReferenceDate: NSTimeInterval {
        return _timeIntervalSinceReferenceDate
    }
    
    convenience init(json: JSON) throws {
        
        if let dateString = json.string, date = JSONDate.dateFormatter.dateFromString(dateString) {
            
            self.init(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate)
        }
        else if let dateString = json.string, date = JSONDate.dateFormatterNoMillis.dateFromString(dateString) {
            
            self.init(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate)
        }
        else {
            throw SwiftyJSONDecodeError.InvalidValue(json.rawString())
        }
    }
    
    override init(timeIntervalSinceReferenceDate ti: NSTimeInterval) {
        _timeIntervalSinceReferenceDate = ti
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

final class JSONURL : NSURL, SwiftyJSONDecodable {
    
    convenience init(json: JSON) throws {
        let urlString : String = try json.decodeAsValue()
        if let _ = NSURL(string: urlString) {
            self.init(string: urlString, relativeToURL: nil)!
        }
        else {
            throw SwiftyJSONDecodeError.InvalidValue(json.rawString())
        }
    }
    
    override init?(string URLString: String, relativeToURL baseURL: NSURL?) {
        super.init(string: URLString, relativeToURL: baseURL)
    }
    
    required convenience init(fileReferenceLiteral path: String) {
        fatalError("init(fileReferenceLiteral:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}