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
    
    public let accountNumber : String
    public let created : NSDate?
    public let description : String
    public let accountId : String
    public let sortCode : String
}

public struct MondoAccountBalance {
    
    public let balance : Int
    public let currency : String
    public let spendToday : Int
}

extension MondoAccount : SwiftyJSONDecodable {
    
    init(json: JSON) throws {
        
        accountNumber = try json.requiredValueForKey("account_number")
        
        let createdString : String = try json.requiredValueForKey("created")
        created = NSDate.dateFromTimestamp(createdString)
        
        description = try json.requiredValueForKey("description")
        accountId = try json.requiredValueForKey("id")
        sortCode = try json.requiredValueForKey("sort_code")
    }
}

extension MondoAccountBalance : SwiftyJSONDecodable {
    
    init(json: JSON) throws {
        
        balance = try json.requiredValueForKey("balance")
        currency = try json.requiredValueForKey("currency")
        spendToday = try json.requiredValueForKey("spend_today")
    }
}