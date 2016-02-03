//
//  MondoAccount.swift
//  MondoKit
//
//  Created by Mike Pollard on 23/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftyJSONDecodable

public struct MondoAccount : Idable {
    
    public let accountNumber : String
    public let created : NSDate
    public let description : String
    public let id : String
    public let sortCode : String
}

public struct MondoAccountBalance {
    
    public let balance : Int
    public let currency : String
    public let spendToday : Int
}

extension MondoAccount : SwiftyJSONDecodable {
    
    public init(json: JSON) throws {
        
        accountNumber = try json.decodeValueForKey("account_number")
        
        created = try json.decodeValueForKey("created") as JSONDate
        description = try json.decodeValueForKey("description")
        id = try json.decodeValueForKey("id")
        sortCode = try json.decodeValueForKey("sort_code")
    }
}

extension MondoAccountBalance : SwiftyJSONDecodable {
    
    public init(json: JSON) throws {
        
        balance = try json.decodeValueForKey("balance")
        currency = try json.decodeValueForKey("currency")
        spendToday = try json.decodeValueForKey("spend_today")
    }
}