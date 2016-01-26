//
//  MondoAddress.swift
//  MondoKit
//
//  Created by Mike Pollard on 26/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation
import SwiftyJSON

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
        
        address = try json.requiredValueForKey("address")
        city = try json.requiredValueForKey("city")
        country = try json.requiredValueForKey("country")
        latitude = try json.requiredValueForKey("latitude")
        longitude = try json.requiredValueForKey("longitude")
        postcode = try json.requiredValueForKey("postcode")
        region = try json.requiredValueForKey("region")
    }
}