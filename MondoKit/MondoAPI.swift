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
import SwiftyJSONDecodable
import KeychainAccess

internal struct AuthData {
    
    private static let OAuth2CreatedAtKey: String = "MondoOAuth2CreatedAt"
    private static let OAuth2AccessTokenKey: String = "MondoOAuth2AccessToken"
    private static let OAuth2RefreshTokenKey: String = "MondoOAuth2RefreshToken"
    private static let OAuth2ExpiresInKey: String = "MondoOAuth2ExpiresInToken"
    
    let createdAt : NSDate
    //let userId : String
    let accessToken : String
    let expiresIn : Int
    let refreshToken : String?
    var expiresAt : NSDate {
        return createdAt.dateByAddingTimeInterval(NSTimeInterval(expiresIn))
    }
    
    internal init(createdAt: NSDate, accessToken: String, expiresIn: Int, refreshToken: String? = nil) {
        self.createdAt = createdAt
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.refreshToken = refreshToken
    }
    
    private init?(keychain: Keychain) {
        
        guard
        let createdAt = keychain[AuthData.OAuth2CreatedAtKey],
        let createdAtDate = JSONDate.dateFormatterNoMillis.dateFromString(createdAt),
        let accessToken = keychain[AuthData.OAuth2AccessTokenKey],
        let expiresIn = keychain[AuthData.OAuth2ExpiresInKey]
            else {
                return nil
        }
        
        self.createdAt = createdAtDate
        self.accessToken = accessToken
        self.expiresIn = Int(expiresIn)!
        self.refreshToken = keychain[AuthData.OAuth2RefreshTokenKey]
    }
    
    internal func storeInKeychain(keychain: Keychain) {
        
        keychain[AuthData.OAuth2CreatedAtKey] = createdAt.toJsonDateTime
        keychain[AuthData.OAuth2AccessTokenKey] = accessToken
        keychain[AuthData.OAuth2RefreshTokenKey] = refreshToken
        keychain[AuthData.OAuth2ExpiresInKey] = String(expiresIn)
    }
}

/**
 A Swift wrapper around the Mondo API at https://api.getmondo.co.uk/
 
 This is a singleton, use `MondAPI.instance` to play with it and call `MondAPI.instance.initialiseWithClientId(:clientSecret)`
 before you do anything else.
 
 Once you've done that grab a `UIViewController` using `newAuthViewController` and present it to allow user authentication.
 
 Then go ahead and play with:
 
 - `listAccounts`
 - `getBalanceForAccount`
 - `listTransactionsForAccount`
 
 */
public class MondoAPI {
    
    internal static let APIRoot = "https://api.getmondo.co.uk/"
    
    /// The only one you'll ever need!
    public static let instance = MondoAPI()
    
    internal var clientId : String?
    internal var clientSecret : String?
    
    internal var authData : AuthData?
    internal var keychain : Keychain!
    
    private var initialised : Bool {
        
        return clientId != nil && clientSecret != nil
    }
    
    private init() { }
    
    public var isAuthorized : Bool {
        
        assert(initialised, "MondoAPI.instance not initialised!")
        
        guard let authData = authData else { return false }
        
        return authData.expiresAt.timeIntervalSinceNow > 60 // Return false if we're expired or about to expire in the next minute
    }
    
    private var authHeader : [String:String]? {
        guard let authData = authData else { return nil }
        return ["Authorization":"Bearer " + authData.accessToken]
    }
    
    /**
     Initializes the MondoAPI instance with the specified clientId & clientSecret.
     
     You need to do this before using the MondAPI.
     
     ie call `MondAPI.instance.initialiseWithClientId(:clientSecret)` in `applicationDidFinishLaunchingWithOptions`
     
     */
    public func initialiseWithClientId(clientId : String, clientSecret : String) {
        
        assert(!initialised, "MondoAPI.instance already initialised!")
        
        self.clientId = clientId
        self.clientSecret = clientSecret
        
        keychain = Keychain(service: MondoAPI.APIRoot + clientId)
        authData = AuthData(keychain: keychain)
    }
    
    /**
     Creates and returns a `UIViewController` that manages authentication with Mondo.
     
     Present this and wait for the callback.
     
     - parameter onCompletion:     The callback closure called to let you know how the authentication went.
     */
    public func newAuthViewController(onCompletion completion : (success : Bool, error : ErrorType?) -> Void) -> UIViewController {
        
        assert(initialised, "MondoAPI.instance not initialised!")
        
        return OAuthViewController(mondoApi: self, onCompletion: completion)
    }
    
    // MARK: Pagination
    
    /**
    A struct to encapsulte the Pagination parameters used by the Mondo API for cursor based pagination.
    */
    public struct Pagination {
        
        public enum Constraint {
            case Date(NSDate)
            case Id(String)
            
            private var headerValue : String {
                switch self {
                case .Date(let date):
                    return date.toJsonDateTime
                case .Id(let id):
                    return id
                }
            }
        }
        
        let limit : Int?
        let since : Constraint?
        let before : NSDate?
        
        public init(limit: Int? = nil, since: Constraint? = nil, before: NSDate? = nil) {
            self.limit = limit
            self.since = since
            self.before = before
        }
        
        private var parameters : [String : String] {
            var parameters = [String:String]()
            if let limit = limit {
                parameters["limit"] = String(limit)
            }
            if let since = since {
                parameters["since"] = since.headerValue
            }
            if let before = before {
                parameters["before"] = before.toJsonDateTime
            }
            return parameters
        }
    }
    
    
    // MARK: internal and private helpers
    
    internal func dispatchCompletion(completion: ()->Void) {
        
        dispatch_async(dispatch_get_main_queue(), completion)
    }
    
    private func errorFromResponse(response: Alamofire.Response<AnyObject, NSError>) -> NSError {
        
        switch response.result {
            
        case .Success(let value):
            
            let json = JSON(value)
            let message = json["message"].string
            return NSError(domain: "MondoAPI", code: response.response?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey:message ?? ""])
            
        case .Failure(let error):
            return error
        }
    }
}

// MARK: listAccounts

extension MondoAPI {
    
    /**
     Calls https://api.getmondo.co.uk/accounts and calls the completion closure with
     either an `[MondoAccount]` or an `ErrorType`
     
     - parameter completion:
    */
    public func listAccounts(completion: (mondoAccounts: [MondoAccount]?, error: ErrorType?) -> Void) {
        
        assert(initialised, "MondoAPI.instance not initialised!")
        
        if let authHeader = self.authHeader {
            
            Alamofire.request(.GET, MondoAPI.APIRoot+"accounts", headers: authHeader).responseJSON { response in
                
                var mondoAccounts : [MondoAccount]?
                var anyError : ErrorType?
                
                defer {
                    self.dispatchCompletion() {
                        completion(mondoAccounts: mondoAccounts, error: anyError)
                    }
                }
                
                guard let status = response.response?.statusCode where status == 200 else {
                    
                    debugPrint(response)
                    anyError = self.errorFromResponse(response)
                    return
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
}

// MARK: getBalanceForAccount

extension MondoAPI {
    
    /**
     Calls https://api.getmondo.co.uk/balance and calls the completion closure with
     either an `MondoAccountBalance` or an `ErrorType`
     
     - parameter account:       an account from which to get the accountId
     - parameter completion:
     */
    public func getBalanceForAccount(account: MondoAccount, completion: (balance: MondoAccountBalance?, error: ErrorType?) -> Void) {
        
        assert(initialised, "MondoAPI.instance not initialised!")
        
        if let authHeader = self.authHeader {
            
            Alamofire.request(.GET, MondoAPI.APIRoot+"balance", parameters: ["account_id" : account.id], headers: authHeader).responseJSON { response in
                
                var balance : MondoAccountBalance?
                var anyError : ErrorType?
                
                defer {
                    self.dispatchCompletion() {
                        completion(balance: balance, error: anyError)
                    }
                }
                
                guard let status = response.response?.statusCode where status == 200 else {
                    
                    debugPrint(response)
                    anyError = self.errorFromResponse(response)
                    return
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

// MARK: getTransactionForId

extension MondoAPI {
    
    /**
     Calls https://api.getmondo.co.uk/transaction/$transaction_id and calls the completion closure with
     either an `MondoTransaction` or an `ErrorType`
     
     - parameter transactionId: a transaction Id
     - parameter expand:        what to pass as expand[] parameter. eg. merchant. `nil` by default.
     - parameter completion:
     */
    public func getTransactionForId(transactionId: String, expand: String? = nil, completion: (transaction: MondoTransaction?, error: ErrorType?) -> Void) {
        
        assert(initialised, "MondoAPI.instance not initialised!")
        
        if let authHeader = self.authHeader {
            
            var parameters = [String:String]()
            if let expand = expand {
                parameters["expand[]"] = expand
            }
            
            Alamofire.request(.GET, MondoAPI.APIRoot+"transactions/"+transactionId, parameters: parameters, headers: authHeader).responseJSON { response in
                
                var transaction : MondoTransaction?
                var anyError : ErrorType?
                
                defer {
                    self.dispatchCompletion() {
                        completion(transaction: transaction, error: anyError)
                    }
                }
                
                guard let status = response.response?.statusCode where status == 200 else {
                    
                    debugPrint(response)
                    anyError = self.errorFromResponse(response)
                    return
                }
                
                switch response.result {
                    
                case .Success(let value):
                    debugPrint(value)
                    
                    let json = JSON(value)
                    do {
                        transaction = try json.decodeValueForKey("transaction") as MondoTransaction
                    }
                    catch {
                        debugPrint("Could not create MondoTransaction from \(json) \n Error: \(error)")
                        anyError = error
                    }
                    
                case .Failure(let error):
                    debugPrint(error)
                    anyError = error
                }
            }
        }
    }
}

// MARK : annotateTransaction

extension MondoAPI {
    
    public func annotateTransaction(transaction: MondoTransaction, withKey key: String, value: String, completion: (transaction: MondoTransaction?, error: ErrorType?) -> Void) {
        
        assert(initialised, "MondoAPI.instance not initialised!")
        
        guard key.characters.count > 0 else {
            self.dispatchCompletion() {
                completion(transaction: transaction, error: nil)
            }
            return
        }
        
        if let authHeader = self.authHeader {
            
            var parameters = ["metadata["+key+"]":value]
            
            Alamofire.request(.PATCH, MondoAPI.APIRoot+"transactions/"+transaction.id, parameters: parameters, headers: authHeader).responseJSON { response in
                
                var transaction : MondoTransaction?
                var anyError : ErrorType?
                
                defer {
                    self.dispatchCompletion() {
                        completion(transaction: transaction, error: anyError)
                    }
                }
                
                guard let status = response.response?.statusCode where status == 200 else {
                    
                    debugPrint(response)
                    anyError = self.errorFromResponse(response)
                    return
                }
                
                switch response.result {
                    
                case .Success(let value):
                    debugPrint(value)
                    
                    let json = JSON(value)
                    do {
                        transaction = try json.decodeValueForKey("transaction") as MondoTransaction
                    }
                    catch {
                        debugPrint("Could not create MondoTransaction from \(json) \n Error: \(error)")
                        anyError = error
                    }
                    
                case .Failure(let error):
                    debugPrint(error)
                    anyError = error
                }
            }
        }

    }
}

// MARK: listTransactionsForAccount

extension MondoAPI {
    
    /**
     Calls https://api.getmondo.co.uk/transactions and calls the completion closure with
     either an `[MondoTransaction]` or an `ErrorType`
     
     - parameter account:       an account from which to get the accountId
     - parameter expand:        what to pass as expand[] parameter. eg. merchant. `nil` by default.
     - parameter pagination:    the pagination parameters. `nil` by default.
     - parameter completion:
     */
    public func listTransactionsForAccount(account: MondoAccount, expand: String? = nil, pagination: Pagination? = nil, completion: (transactions: [MondoTransaction]?, error: ErrorType?) -> Void) {
        
        assert(initialised, "MondoAPI.instance not initialised!")
        
        if let authHeader = self.authHeader {
            
            var parameters = ["account_id" : account.id]
            if let expand = expand {
                parameters["expand[]"] = expand
            }
            
            if let pagination = pagination {
                pagination.parameters.forEach { parameters.updateValue($1, forKey: $0) }
            }
            
            Alamofire.request(.GET, MondoAPI.APIRoot+"transactions", parameters: parameters, headers: authHeader).responseJSON { response in
                
                var transactions : [MondoTransaction]?
                var anyError : ErrorType?
                
                defer {
                    self.dispatchCompletion() {
                        completion(transactions: transactions, error: anyError)
                    }
                }
                
                guard let status = response.response?.statusCode where status == 200 else {
                    
                    debugPrint(response)
                    anyError = self.errorFromResponse(response)
                    return
                }
                
                switch response.result {
                    
                case .Success(let value):
                    debugPrint(value)
                    
                    let json = JSON(value)
                    do {
                        transactions = try json.decodeArrayForKey("transactions")
                    }
                    catch {
                        debugPrint("Could not create MondoTransactions from \(json) \n Error: \(error)")
                        anyError = error
                    }
                    
                case .Failure(let error):
                    debugPrint(error)
                    anyError = error
                }
            }
        }
    }
}

extension MondoAPI {
    
    /**
     Calls https://api.getmondo.co.uk/feed and calls the completion closure with
     either an `[MondoFeedItem]` or an `ErrorType`
     
     - parameter account:       an account from which to get the accountId
     - parameter completion:
     */
    public func listFeedForAccount(account: MondoAccount, completion: (items: [MondoFeedItem]?, error: ErrorType?) -> Void) {
        
        assert(initialised, "MondoAPI.instance not initialised!")
        
        if let authHeader = self.authHeader {
            
            var parameters = ["account_id" : account.id]
            
            Alamofire.request(.GET, MondoAPI.APIRoot+"feed", parameters: parameters, headers: authHeader).responseJSON { response in
                
                var items : [MondoFeedItem]?
                var anyError : ErrorType?
                
                defer {
                    self.dispatchCompletion() {
                        completion(items: items, error: anyError)
                    }
                }
                
                guard let status = response.response?.statusCode where status == 200 else {
                    
                    debugPrint(response)
                    anyError = self.errorFromResponse(response)
                    return
                }
                
                switch response.result {
                    
                case .Success(let value):
                    debugPrint(value)
                    
                    let json = JSON(value)
                    do {
                        items = try json.decodeArrayForKey("items")
                    }
                    catch {
                        debugPrint("Could not create MondoTransactions from \(json) \n Error: \(error)")
                        anyError = error
                    }
                    
                case .Failure(let error):
                    debugPrint(error)
                    anyError = error
                }
            }
        }
    }
}