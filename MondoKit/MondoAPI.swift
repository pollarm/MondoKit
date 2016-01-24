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


internal struct AuthData {
    
    let createdAt = NSDate()
    let userId : String
    let accessToken : String
    let expiresIn : Int
    let refreshToken : String?
    var expiresAt : NSDate {
        return createdAt.dateByAddingTimeInterval(NSTimeInterval(expiresIn))
    }
}

public class MondoAPI {
    
    internal static let APIRoot = "https://api.getmondo.co.uk/"//"https://production-api.gmon.io/"
    
    public static let instance = MondoAPI()
    
    internal var clientId : String?
    internal var clientSecret : String?
    
    internal var authData : AuthData?
    
    private var initialised : Bool {
        
        return clientId != nil && clientSecret != nil
    }
    
    private init() { }
    
    public func initialiseWithClientId(clientId : String, clientSecret : String) {
        
        assert(!initialised, "MondoAPI.instance already initialised!")
        
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
    
    internal func dispatchCompletion(completion: ()->Void) {
        
        dispatch_async(dispatch_get_main_queue(), completion)
    }
    
    public func newAuthViewController(onCompletion onCompletion : (success : Bool, error : ErrorType?) -> Void) -> UIViewController {
        
        assert(initialised, "MondoAPI.instance not initialised!")
        
        return OAuthViewController(mondoApi: self, onCompletion: onCompletion)
    }
    
    public func listAccounts(completion: (mondoAccounts: [MondoAccount]?, error: ErrorType?) -> Void) {
        
        assert(initialised, "MondoAPI.instance not initialised!")
        
        if let authData = authData {
            
            Alamofire.request(.GET, MondoAPI.APIRoot+"accounts", headers: ["Authorization":"Bearer " + authData.accessToken]).responseJSON { response in
             
                var mondoAccounts : [MondoAccount]?
                var anyError : ErrorType?
                
                defer {
                    self.dispatchCompletion() {
                        completion(mondoAccounts: mondoAccounts, error: anyError)
                    }
                }
                
                switch response.result {
                    
                case .Success(let value):
                    
                    debugPrint(value)
                    
                    mondoAccounts = [MondoAccount]()
                    
                    let json = JSON(value)
                    if let accounts = json["accounts"].array {
                        for accountJson in accounts {
                            do {
                                let mondoAccount = try MondoAccount(json: accountJson)
                                mondoAccounts!.append(mondoAccount)
                            }
                            catch {
                                debugPrint("Could not create MondoAccount from \(accountJson) \n Error: \(error)")
                            }
                        }
                    }
                    
                case .Failure(let error):
                    
                    debugPrint(error)
                }
            }
            
        }
    }
    
    public func getBalanceForAccount(account: MondoAccount, completion: (balance: MondoAccountBalance?, error: ErrorType?) -> Void) {
        
        assert(initialised, "MondoAPI.instance not initialised!")
        
        if let authData = authData {
            
            Alamofire.request(.GET, MondoAPI.APIRoot+"balance", parameters: ["account_id" : account.accountId], headers: ["Authorization":"Bearer " + authData.accessToken]).responseJSON { response in
            
                var balance : MondoAccountBalance?
                var anyError : ErrorType?
                
                defer {
                    self.dispatchCompletion() {
                        completion(balance: balance, error: anyError)
                    }
                }
                
                switch response.result {
                    
                case .Success(let value):
                    debugPrint(value)
                    
                    let json = JSON(value)
                    do {
                        balance = try MondoAccountBalance(json: json)
                    }
                    catch {
                        debugPrint("Could not create MondoAccountBalance from \(json) \n Error: \(error)")
                        anyError = error
                    }

                case .Failure(let error):
                    debugPrint(error)
                }
            
            }

        }
    }
}