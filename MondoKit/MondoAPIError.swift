//
//  MondoAPIError.swift
//  MondoKit
//
//  Created by Mike Pollard on 08/02/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import SwiftyJSON

public protocol ErrorWithLocalizedDescription {
    
    func getLocalizedDescription() -> String?
}

public enum MondoAPIError : ErrorType, ErrorWithLocalizedDescription {
    
    case RequestFailed(message: String)
    case CouldNotAuthenticate(message: String)
    case BadAccessToken(message: String)
    case Other(message: String)
    case Unknown
    
    public func getLocalizedDescription() -> String? {
        
        switch self {
        case .RequestFailed(let m): return m
        case .CouldNotAuthenticate(let m): return m
        case .BadAccessToken(let m): return m
        case .Other(let m): return m
        default:
            return "Unknown error"
        }
    }
    
    static func apiErrorfromJson(json: JSON) -> MondoAPIError {
        if let code = json["code"].string, message = json["message"].string {
            
            switch code {
            case "internal_service.request_failed":
                return MondoAPIError.RequestFailed(message: message)
            case "bad_request.could_not_authenticate":
                return MondoAPIError.CouldNotAuthenticate(message: message)
            case "unauthorized.bad_access_token":
                return MondoAPIError.BadAccessToken(message: message)
            default:
                return MondoAPIError.Other(message: message)
            }
            
        }
        else if let message = json["message"].string {
            return MondoAPIError.Other(message: message)
        }
        else {
            return MondoAPIError.Unknown
        }
    }
}

