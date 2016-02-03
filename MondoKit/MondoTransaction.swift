//
//  MondoTransaction.swift
//  MondoKit
//
//  Created by Mike Pollard on 24/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftyJSONDecodable

public struct MondoTransaction : Idable {

    public enum DeclineReason : String, SwiftyJSONDecodable {
        case InsufficientFunds = "INSUFFICIENT_FUNDS"
        case CardInactive = "CARD_INACTIVE"
        case CardBlocked = "CARD_BLOCKED"
        case Other = "OTHER"
    }
    
    public let id : String
    public let accountBalance : Int
    public let currency : String
    public let amount : Int
    public let description : String
    public let declineReason : DeclineReason?
    public let category : MondoCategory
    public let created : NSDate
    public let isLoad : Bool
    public let localCurrency : String
    public let localAmount : Int
    public let merchant : IdExpandable<MondoMerchant>?
    public let settled : NSDate?
    public let notes : String?
    
    public let attachments : [MondoAttachment]?
    
    public let metaData : [String:String]
}

extension MondoTransaction : SwiftyJSONDecodable {
    
    public init(json: JSON) throws {
        
        id = try json.decodeValueForKey("id")
        accountBalance = try json.decodeValueForKey("account_balance")
        currency = try json.decodeValueForKey("currency")
        amount = try json.decodeValueForKey("amount")
        description = try json.decodeValueForKey("description")
        declineReason = try json.decodeValueForKey("decline_reason")
        category = try json.decodeValueForKey("category")
        
        created = try json.decodeValueForKey("created") as JSONDate
        
        isLoad = try json.decodeValueForKey("is_load")
        
        localCurrency = try json.decodeValueForKey("local_currency")
        localAmount = try json.decodeValueForKey("local_amount")
        
        merchant = try json.decodeValueForKey("merchant")
        
        settled = try? json.decodeValueForKey("settled") as JSONDate
        
        notes = try json.decodeValueForKey("notes")
        
        attachments = try json.decodeArrayForKey("attachments")

        metaData = try json.decodeAsDictionaryForKey("metadata")

    }
}