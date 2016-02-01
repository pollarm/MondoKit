//
//  SwiftyJSONDecodable.swift
//  MondoKit
//
//  Created by Mike Pollard on 21/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//


import Foundation
import SwiftyJSON

/// Conform to this if you can be instantiated from a json representation
/// in the form of a SwiftyJSON.JSON
public protocol SwiftyJSONDecodable {
    
    /// An initialiser that take a JSON and throws
    ///
    /// The intention here is that the implementation can `throw` if the json
    /// is malformatted, missing required fields etc.
    init(json: JSON) throws
    
}

/// An ErrorType encapsulating the various different failure states
/// while decoding from json
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


extension Array where Element: SwiftyJSONDecodable {

    public init(json: JSON) throws {
        
        guard json != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        
        guard let arrayJSON = json.array else { throw SwiftyJSONDecodeError.WrongType }
        
        var index = 0
        var elements = [Element]()
        do {
            for elementJson in arrayJSON {
                let element = try Element(json: elementJson)
                elements.append(element)
                index = index + 1
            }
        }
        catch let error as SwiftyJSONDecodeError {
            throw SwiftyJSONDecodeError.ErrorForKey(key: "["+String(index)+"]", error: error)
        }
        
        self.init(elements)
    }
}

extension Dictionary where Key : StringLiteralConvertible, Key.StringLiteralType == String, Value: SwiftyJSONDecodable {
    
    public init(json: JSON) throws {
        
        guard json != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        
        guard let dictJSON = json.dictionary else { throw SwiftyJSONDecodeError.WrongType }
        
        var result = [String:Value]()
        for (k, j) in dictJSON {
            let v : Value = try Value(json: j)
            result[k] = v
        }
        
        self.init()
        for (k, v) in result {
            let key = Key(stringLiteral: k)
            self[key] = v
        }
    }
}

extension JSON {
    
    func decodeArrayForKey<T: SwiftyJSONDecodable>(key: String) throws -> Array<T>? {
        
        guard self.type != .Null else { throw SwiftyJSONDecodeError.NullValue }
        guard self.type == .Dictionary else { throw SwiftyJSONDecodeError.WrongType }
        
        guard self[key] != JSON.null else { return nil }
        
        return try decodeArrayForKey(key) as Array<T>
    }
    
    func decodeArrayForKey<T: SwiftyJSONDecodable>(key: String) throws -> Array<T> {
        
        guard self.type != .Null else { throw SwiftyJSONDecodeError.NullValue }
        guard self.type == .Dictionary else { throw SwiftyJSONDecodeError.WrongType }
        
        do {
            let json = self[key]
            return try Array<T>(json: json)
        }
        catch let error as SwiftyJSONDecodeError {
            throw SwiftyJSONDecodeError.ErrorForKey(key: key, error: error)
        }
    }
    
    func decodeValueForKey<T: SwiftyJSONDecodable>(key: String) throws -> T? {
        
        guard self.type != .Null else { throw SwiftyJSONDecodeError.NullValue }
        guard self.type == .Dictionary else { throw SwiftyJSONDecodeError.WrongType }
        
        guard self[key] != JSON.null else { return nil }
        
        return try self.decodeValueForKey(key) as T
    }
    
    func decodeValueForKey<T: SwiftyJSONDecodable>(key: String) throws -> T {
        
        guard self.type != .Null else { throw SwiftyJSONDecodeError.NullValue }
        guard self.type == .Dictionary else { throw SwiftyJSONDecodeError.WrongType }
        
        do {
            let json = self[key]
            return try json.decodeAsValue()
        }
        catch let error as SwiftyJSONDecodeError {
            throw SwiftyJSONDecodeError.ErrorForKey(key: key, error: error)
        }
    }
    
    func decodeAsValue<T: SwiftyJSONDecodable>() throws -> T? {
        
        guard self != JSON.null else { return nil }
        
        return try T(json: self)
    }

    
    func decodeAsValue<T: SwiftyJSONDecodable>() throws -> T {
        
        guard self != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        
        return try T(json: self)
    }
    
    func decodeAsDictionaryForKey<V: SwiftyJSONDecodable>(key: String) throws -> Dictionary<String, V> {
        
        guard self.type != .Null else { throw SwiftyJSONDecodeError.NullValue }
        guard self.type == .Dictionary else { throw SwiftyJSONDecodeError.WrongType }
        
        do {
            let json = self[key]
            return try Dictionary<String, V>(json : json)
        }
        catch let error as SwiftyJSONDecodeError {
            throw SwiftyJSONDecodeError.ErrorForKey(key: key, error: error)
        }
    }
}

/// Make all RawRepresentables conform to SwiftyJSONDecodable where the associated RawValue is SwiftyJSONDecodable
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