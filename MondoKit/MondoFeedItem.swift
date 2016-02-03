//
//  MondoFeedItem.swift
//  MondoKit
//
//  Created by Mike Pollard on 31/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftyJSONDecodable

public struct MondoFeedItem : Idable {
    
    public enum Type : String, SwiftyJSONDecodable {
        case Transaction = "transaction"
        case Basic = "basic"
        case OnboardingSearch = "onboarding_search"
        case OnboardingGraph = "onboarding_graph"
        
        case Unknown = "UNKNOWN"
        
        public init(json: JSON) throws {
        
            guard json != JSON.null else { throw SwiftyJSONDecodeError.NullValue }
            guard let rawValue = json.rawValue as? String else { throw SwiftyJSONDecodeError.WrongType }
            if let _ = Type(rawValue: rawValue) {
                self.init(rawValue: rawValue)!
            }
            else {
                self.init(rawValue: "UNKNOWN")!
            }

        }
    }
    
    public let id : String
    public let type : Type
    public let accountId : String
    //public let attachments : [MondoAttachment]? // they json keys are slightly different for attachments in a feed.transaction.
    public let created : NSDate
    public let updated : NSDate
    public let externalId : String
    public let params : [String:String]?
    public let isRead : Bool
    
    public let transaction : MondoTransaction?
}

extension MondoFeedItem : SwiftyJSONDecodable {
    
    public init(json: JSON) throws {
        
        id = try json.decodeValueForKey("id")
        type = try json .decodeValueForKey("type")
        
        accountId = try json.decodeValueForKey("account_id")
        //attachments = try json.decodeArrayForKey("attachments")
        created = try json.decodeValueForKey("created") as JSONDate
        updated = try json.decodeValueForKey("updated") as JSONDate
        externalId = try json.decodeValueForKey("external_id")
        params = try json.decodeAsDictionaryForKey("params")
        isRead = try json.decodeValueForKey("read")
        
        transaction = try json .decodeValueForKey("transaction")
    }

}
