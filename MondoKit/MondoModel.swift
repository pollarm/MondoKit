//
//  MondoModel.swift
//  MondoKit
//
//  Created by Mike Pollard on 26/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftyJSONDecodable

public protocol Idable {
    
    var id : String { get }
}

public enum IdExpandable<Value : SwiftyJSONDecodable where Value : Idable> : Idable {
    
    case Id(String)
    case Expanded(Value)
    
    public var id : String {
        switch self {
        case .Id(let s): return s
        case .Expanded(let m): return m.id
        }
    }

    public var expandedObject : Value? {
        switch self {
        case .Id: return nil
        case .Expanded(let m): return m
        }
    }
}

extension IdExpandable : SwiftyJSONDecodable {
    
    public init(json: JSON) throws {
        if let id = json.string { self = .Id(id) }
        else {
            self = .Expanded(try json.decodeAsValue() as Value)
        }
    }
}