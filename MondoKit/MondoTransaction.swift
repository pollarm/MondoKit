//
//  MondoTransaction.swift
//  MondoKit
//
//  Created by Mike Pollard on 24/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation
import SwiftyJSON

public struct MondoTransaction {

    public let transactionId : String
    public let accountBalance : Int
    public let currency : String
    public let amount : Int
    public let description : String
    public let category : MondoCategory
    public let created : NSDate
    public let isLoad : Bool
    public let localCurrency : String
    public let localAmount : Int
    public let merchant : IdExpandable<MondoMerchant>?
    public let settled : NSDate?
    public let notes : String
    
    public let attachments : [MondoAttachment]
    
    public let metaData : [String:String]
}

extension MondoTransaction : SwiftyJSONDecodable {
    
    public init(json: JSON) throws {
        
        transactionId = try json.requiredValueForKey("id")
        accountBalance = try json.requiredValueForKey("account_balance")
        currency = try json.requiredValueForKey("currency")
        amount = try json.requiredValueForKey("amount")
        description = try json.requiredValueForKey("description")
        category = try json.requiredValueForKey("category")
        
        created = try json.requiredValueForKey("created") as JSONDate
        
        isLoad = try json.requiredValueForKey("is_load")
        
        localCurrency = try json.requiredValueForKey("local_currency")
        localAmount = try json.requiredValueForKey("local_amount")
        
        merchant = try? json.requiredValueForKey("merchant")
        
        settled = try? json.requiredValueForKey("settled") as JSONDate
        
        notes = try json.requiredValueForKey("notes")
        
        attachments = try json.requiredArrayForKey("attachments")

        metaData = try json.requiredAsDictionaryForKey("metadata")

    }
}