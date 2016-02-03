//
//  MondoMerchant.swift
//  MondoKit
//
//  Created by Mike Pollard on 26/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftyJSONDecodable

public struct MondoMerchant : Idable {
    
    public let id : String
    public let address : MondoAddress
    public let created : NSDate
    public let groupId : String
    public let logoUrl : NSURL
    public let emoji : String
    public let name : String
    public let category : MondoCategory
}

extension MondoMerchant : SwiftyJSONDecodable {
    
    public init(json: JSON) throws {
        
        id = try json.decodeValueForKey("id") as String
        address = try json.decodeValueForKey("address")
        created = try json.decodeValueForKey("created") as JSONDate
        groupId = try json.decodeValueForKey("group_id")
        logoUrl = try json.decodeValueForKey("logo") as JSONURL
        emoji = try json.decodeValueForKey("emoji")
        name = try json.decodeValueForKey("name")
        category = try json.decodeValueForKey("category")
    }
    
}
