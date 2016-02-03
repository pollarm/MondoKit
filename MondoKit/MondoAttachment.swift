//
//  MondoAttachment.swift
//  MondoKit
//
//  Created by Mike Pollard on 26/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftyJSONDecodable

public struct MondoAttachment : Idable {
    
    public let id : String
    public let created : NSDate
    public let type : String
    public let url : NSURL
}

extension MondoAttachment : SwiftyJSONDecodable {
    
    public init(json: JSON) throws {
        
        id = try json.decodeValueForKey("id")
        created = try json.decodeValueForKey("created") as JSONDate
        type = try json.decodeValueForKey("type")
        url = try json.decodeValueForKey("url") as JSONURL
    }
}

