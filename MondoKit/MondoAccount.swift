//
//  MondoAccount.swift
//  MondoKit
//
//  Created by Mike Pollard on 23/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation
import SwiftyJSON

public struct MondoAccount {
    
    let accountNumber : String
    let created : NSDate
    let description : String
    let accountId : String
    let sortCode : String
}

extension MondoAccount : SwiftyJSONDecodable {
    
    init(json: JSON) throws {
        
        accountNumber = try json.requiredValueForKey("account_number")
        let createdString : String = try json.requiredValueForKey("created")
        created = NSDate.dateFromTimestamp(createdString)!
        description = try json.requiredValueForKey("description")
        accountId = try json.requiredValueForKey("id")
        sortCode = try json.requiredValueForKey("sort_code")
    }
}
