//
//  MondoMerchant.swift
//  MondoKit
//
//  Created by Mike Pollard on 26/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation
import SwiftyJSON

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
        
        id = try json.requiredValueForKey("id") as String
        address = try json.requiredValueForKey("address")
        created = try json.requiredValueForKey("created") as JSONDate
        groupId = try json.requiredValueForKey("group_id")
        logoUrl = try json.requiredValueForKey("logo") as JSONURL
        emoji = try json.requiredValueForKey("emoji")
        name = try json.requiredValueForKey("name")
        category = try json.requiredValueForKey("category")
    }
    
}
