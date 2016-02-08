//
//  MondoAPIOAuth.swift
//  MondoKit
//
//  Created by Mike Pollard on 23/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


class OAuthViewController : UIViewController {
    
    private var webView : UIWebView!
    
    private var mondoApi : MondoAPI
    
    private var onCompletion : (success : Bool, error : ErrorType?) -> Void
    
    private var state : String?
    
    init(mondoApi : MondoAPI, onCompletion : (success : Bool, error : ErrorType?) -> Void) {
        
        self.mondoApi = mondoApi
        self.onCompletion = onCompletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        
        webView = UIWebView()
        
        webView.delegate = self
        
        view = webView
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let uuid = NSUUID()
        state = uuid.UUIDString
        
        if let state = state {
            
            var url = MondoAPI.AUTHRoot + "?client_id=" + mondoApi.clientId!
            url = url + "&redirect_uri=" + MondoAPI.AUTHRedirectUri
            url = url + "&response_type=code"
            url = url + "&state=" + state
            
            if let url = NSURL(string: url) {
                let request = NSURLRequest(URL: url)
                webView.loadRequest(request)
            }
        }
    }
}

extension OAuthViewController : UIWebViewDelegate {
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        if let url = request.URL where url.scheme == MondoAPI.AUTHRedirectScheme {
            
            let queryParams = url.queryParams
            if let state = queryParams["state"], code = queryParams["code"] where state == self.state {
                
                MondoAPI.instance.authorizeFromCode(code, completion: onCompletion)
                
                return false
            }
        }
        
        return true
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        onCompletion(success: false, error: error)
    }
}

extension MondoAPI {
    
    private static let AUTHRoot = "https://auth.getmondo.co.uk/"
    private static let AUTHRedirectScheme = "mondoapi"
    private static let AUTHRedirectUri = AUTHRedirectScheme + "://success"

    /// Only to be used for development purposes to access your own account.
    public func authorizeFromUsername(userName: String, andPassword password: String, completion: (success: Bool, error: ErrorType?) -> Void) -> Void {
    
        let parameters = [
            "grant_type": "password",
            "client_id": clientId!,
            "client_secret": clientSecret!,
            "username" : userName,
            "password" : password
        ]
        
        apiOperationQueue.addOperation(authorizeOperationWithParameters(parameters, completion: completion))
    }
    
    func reauthorizeOperationFromRefreshToken(refreshToken: String, completion: (success: Bool, error: ErrorType?) -> Void) -> MondoAPIOperation {
        
        let parameters = [
            "grant_type": "refresh_token",
            "client_id": clientId!,
            "client_secret": clientSecret!,
            "refresh_token" : refreshToken
        ]
        
        return authorizeOperationWithParameters(parameters, completion: completion)
        
    }
    
    func authorizeFromCode(code : String, completion: (success: Bool, error: ErrorType?) -> Void) -> Void {
        
        let parameters = [
            "grant_type": "authorization_code",
            "client_id": clientId!,
            "client_secret": clientSecret!,
            "redirect_uri" : MondoAPI.AUTHRedirectUri,
            "code" : code
        ]
        
        apiOperationQueue.addOperation(authorizeOperationWithParameters(parameters, completion: completion))
        
    }
    
    private func authorizeOperationWithParameters(parameters: [String:String], completion: (success: Bool, error: ErrorType?) -> Void) -> MondoAPIOperation {
        
        let operation = MondoAPIOperation(method: .POST, urlString: MondoAPI.APIRoot+"oauth2/token", parameters: parameters) { (json, error) in
            
            var success : Bool = false
            var anyError : ErrorType?
            
            defer {
                self.dispatchCompletion() {
                    completion(success: success, error: anyError)
                }
            }
            
            guard error == nil else { anyError = error; return }
            
            if let json = json,
                _ = json["user_id"].string,
                accessToken = json["access_token"].string,
                expiresIn = json["expires_in"].int {
                    
                    let refreshToken = json["refresh_token"].string
                    self.authData = AuthData(createdAt: NSDate(), accessToken: accessToken, expiresIn: expiresIn, refreshToken: refreshToken)
                    self.authData!.storeInKeychain(self.keychain)
                    success = true
            }
            else {
                anyError = MondoAPIError.Unknown
            }
            
        }
        return operation
    }

}

extension NSURL {
    
    var queryParams : [String : String] {
        get {
            var params = [String: String]()
            
            if let queryString = self.query {
                
                for part in queryString.componentsSeparatedByString("&") {
                    let split = part.componentsSeparatedByString("=")
                    guard split.count == 2 else { continue }
                    if let key = split[0].stringByRemovingPercentEncoding, value = split[1].stringByRemovingPercentEncoding {
                        params[key] = value
                    }
                }
            }
            
            return params
        }
    }
}
