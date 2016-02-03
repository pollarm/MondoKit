//
//  MondoAddress.swift
//  MondoKit
//
//  Created by Mike Pollard on 26/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftyJSONDecodable

public struct MondoAddress {
    
    public let address : String
    public let city : String
    public let country : String
    public let latitude : Double
    public let longitude : Double
    public let postcode : String
    public let region : String
}

extension MondoAddress : SwiftyJSONDecodable {
    
    public init(json: JSON) throws {
        
        address = try json.decodeValueForKey("address")
        city = try json.decodeValueForKey("city")
        country = try json.decodeValueForKey("country")
        latitude = try json.decodeValueForKey("latitude")
        longitude = try json.decodeValueForKey("longitude")
        postcode = try json.decodeValueForKey("postcode")
        region = try json.decodeValueForKey("region")
    }
}