//
//  SwiftyJSONDecodable.swift
//  MondoKit
//
//  Created by Mike Pollard on 21/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//


import Foundation
import SwiftyJSON

protocol SwiftyJSONDecodable {
    
    init(json: JSON) throws
    
}

indirect enum SwiftyJSONDecodeError : ErrorType {
    
    case NullValue
    case WrongType
    case InvalidValue
    case ErrorForKey(key: String, error: SwiftyJSONDecodeError)
}

extension SwiftyJSONDecodeError : CustomDebugStringConvertible {
    
    var debugDescription: String {
        switch self {
        case NullValue : return "NullValue"
        case WrongType : return "WrongType"
        case InvalidValue : return "InvalidValue"
        case ErrorForKey(let key, let error) :
            return key + "." + error.debugDescription
        }
    }
}

extension Int : SwiftyJSONDecodable {
    
    init(json: JSON) throws {
        guard json != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        guard let i = json.int else { throw SwiftyJSONDecodeError.WrongType }
        self.init(i)
    }
}

extension String : SwiftyJSONDecodable {
    
    init(json: JSON) throws {
        guard json != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        guard let s = json.string else { throw SwiftyJSONDecodeError.WrongType }
        self.init(s)
    }
}

extension Bool : SwiftyJSONDecodable {
    
    init(json :JSON) throws {
        guard json != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        guard let b = json.bool else { throw SwiftyJSONDecodeError.WrongType }
        self.init(b)
    }
}

extension JSON {
    
    func requiredAsArray<T: SwiftyJSONDecodable>(onDecodeElement onDecodeElement:((elementWasDecoded: T, fromJSON: JSON) throws ->())? = nil) throws -> Array<T> {
    
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
    
    func requiredArrayForKey<T: SwiftyJSONDecodable>(key: String, onDecodeElement:((elementWasDecoded: T, fromJSON: JSON) throws ->())? = nil) throws -> Array<T> {
        
        do {
            let json = self[key]
            return try json.requiredAsArray(onDecodeElement: onDecodeElement)
        }
        catch let error as SwiftyJSONDecodeError {
            throw SwiftyJSONDecodeError.ErrorForKey(key: key, error: error)
        }
    }
    
    func requiredValueForKey<T: SwiftyJSONDecodable>(key: String) throws -> T {
        
        do {
            let json = self[key]
            return try json.requiredAsValue()
        }
        catch let error as SwiftyJSONDecodeError {
            throw SwiftyJSONDecodeError.ErrorForKey(key: key, error: error)
        }
    }
    
    func requiredAsValue<T: SwiftyJSONDecodable>() throws -> T {
        
        guard self != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        
        return try T(json: self)
    }

}

extension SwiftyJSONDecodable where Self : RawRepresentable, Self.RawValue : SwiftyJSONDecodable {
    
    init(json: JSON) throws {
        guard json != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
        guard let rawValue = json.rawValue as? Self.RawValue else { throw SwiftyJSONDecodeError.WrongType }
        if let _ = Self(rawValue: rawValue) {
            self.init(rawValue: rawValue)!
        }
        else {
            throw SwiftyJSONDecodeError.InvalidValue
        }
    }
    
}

extension NSDate {
    
    static func dateFromTimestamp(timestamp : String) -> NSDate? {
        
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        return formatter.dateFromString(timestamp)
    }
}