//
//  MondoAPI.swift
//  MondoKit
//
//  Created by Mike Pollard on 21/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


public enum LoginError : ErrorType {
    
    case RequestFailed(String)
    case CouldNotAuthenticate(String)
    case Other(String)
    case Unknown
    
    public func getLocalizedFailureReason() -> String? {
        
        switch self {
        case .RequestFailed(let s): return s
        case .CouldNotAuthenticate(let s): return s
        case .Other(let s): return s
        default:
            return "Unknown error"
        }
    }
}


public class MondoAPI {
    
    private struct AuthData {
        
        let usedId : String
        let accessToken : String
        let refreshToken : String?
        let expiresAt : NSDate
    }
    
    private static let APIRoot = "https://api.getmondo.co.uk/"//"https://production-api.gmon.io/"
    static let AUTHRoot = "https://auth.getmondo.co.uk/"
    static let AUTHRedirectScheme = "mondoapi"
    static let AUTHRedirectUri = AUTHRedirectScheme + "://success"
    
    public static let instance = MondoAPI()
    
    private var clientId : String?
    private var clientSecret : String?
    
    private var authData : AuthData?
    
    private var initialised : Bool {
        
        return clientId != nil && clientSecret != nil
    }
    
    private init() { }
    
    public func initialiseWithClientId(clientId : String, clientSecret : String) {
        
        assert(!initialised, "MondoAPI.instance already initialised!")
        
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
    
    public func newAuthViewController(onCompletion onCompletion : (success : Bool, error : LoginError?) -> Void) -> UIViewController {
        
        assert(initialised, "MondoAPI.instance not initialised!")
        
        return OAuthViewController(clientId: clientId!, onCompletion: onCompletion)
    }
    
    public func listAccounts(completion: (mondoAccounts: [MondoAccount]?, error: NSError?) -> Void) {
        
        assert(initialised, "MondoAPI.instance not initialised!")
        
        if let authData = authData {
            
            Alamofire.request(.GET, MondoAPI.APIRoot+"accounts", headers: ["Authorization":"Bearer " + authData.accessToken]).responseJSON { response in
             
                switch response.result {
                    
                case .Success(let value):
                    
                    debugPrint(value)
                    
                    var mondoAccounts = [MondoAccount]()
                    
                    let json = JSON(value)
                    if let accounts = json["accounts"].array {
                        for accountJson in accounts {
                            do {
                                let mondoAccount = try MondoAccount(json: accountJson)
                                mondoAccounts.append(mondoAccount)
                            }
                            catch {
                                debugPrint("Could not create MondoAccount from \(accountJson) \n Error: \(error)")
                            }
                        }
                    }
                    
                    completion(mondoAccounts: mondoAccounts, error: nil)
                    
                case .Failure(let error):
                    
                    debugPrint(error)
                    
                    completion(mondoAccounts: nil, error: error)
                }
            }
            
        }
    }
    
    /*public func getBalanceForAccount(account: MondoAccount) {
        
        
    }*/
    
    func authorizeFromCode(code : String, completion: (success: Bool, error: LoginError?) -> Void) -> Void {
        
        assert(initialised, "MondoAPI.instance not initialised!")
        
        let parameters = [
            "grant_type": "authorization_code",
            "client_id": clientId!,
            "client_secret": clientSecret!,
            "redirect_uri" : MondoAPI.AUTHRedirectUri,
            "code" : code
        ]
        
        Alamofire.request(.POST, MondoAPI.APIRoot+"oauth2/token", parameters: parameters).responseJSON { response in
            
            switch response.result {
                
            case .Success(let value as [String : AnyObject]):
                
                debugPrint(value)
                
                if let userId = value["user_id"] as? String,
                    accessToken = value["access_token"] as? String,
                    expiresIn = value["expires_in"] as? Int {
                        
                        let refreshToken = value["refresh_token"] as? String
                        let expiresAt = NSDate().dateByAddingTimeInterval(NSTimeInterval(expiresIn))
                        self.authData = AuthData(usedId: userId, accessToken: accessToken, refreshToken: refreshToken, expiresAt: expiresAt)
                        
                        completion(success: true, error: nil)
                }
                else if let code = value["code"] as? String, message = value["message"] as? String {
                    
                    let loginError : LoginError
                    switch code {
                    case "internal_service.request_failed":
                        loginError = LoginError.RequestFailed(message)
                    case "bad_request.could_not_authenticate":
                        loginError = LoginError.CouldNotAuthenticate(message)
                    default:
                        loginError = LoginError.Other(message)
                    }
                    completion(success: false, error: loginError)
                }
                else {
                    
                    completion(success: false, error: LoginError.Unknown)
                }
                
            case .Failure(let error):
                debugPrint(error)
                completion(success: false, error: LoginError.Other(error.localizedFailureReason ?? ""))
                
            default:
                debugPrint(response)
                completion(success: false, error: LoginError.Unknown)
            }
        }


    }
    
        /*

        garbage in
        
        ["message": Something went wrong processing this request, "params": {
        "Client-Endpoint" = handlehttp;
        "Client-Service" = "service.api.oauth2";
        "Client-Uid" = api;
        }, "code": internal_service.request_failed]
        
        incorrect password
        
        ["message": Could not authenticate with credentials provided, "params": {
        "Client-Endpoint" = handlehttp;
        "Client-Service" = "service.api.oauth2";
        "Client-Uid" = api;
        }, "code": bad_request.could_not_authenticate]
        
        good login
        
        ["refresh_token": eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhaSI6InRva18wMDAwOTRPWmVodmNHQnRWNUNETkpKIiwiY2kiOiJvYXV0aGNsaWVudF8wMDAwOTRLTlQxNzk3cDdqZ240eVpkIiwiaWF0IjoxNDUzNDE1NjEwLCJ1aSI6InVzZXJfMDAwMDk0SzJnS2Q3bU5kQmhLOXhzZiIsInYiOiIxIn0.1tMUz2-CLsa0FRhNjzy5dwU1q9tpSgrNq6fJ5NLQehQ, "user_id": user_000094K2gKd7mNdBhK9xsf, "client_id": oauthclient_000094KNT1797p7jgn4yZd, "access_token": eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjaSI6Im9hdXRoY2xpZW50XzAwMDA5NEtOVDE3OTdwN2pnbjR5WmQiLCJleHAiOjE0NTM1ODg0MTAsImlhdCI6MTQ1MzQxNTYxMCwianRpIjoidG9rXzAwMDA5NE9aZWh2Y0dCdFY1Q0ROSkoiLCJ1aSI6InVzZXJfMDAwMDk0SzJnS2Q3bU5kQmhLOXhzZiIsInYiOiIxIn0.M8UmuTr0b2ycgvGNLmaJds501bjQ3f2jzHGf7h8o3Uc, "token_type": Bearer, "expires_in": 172799]
        
        */
}