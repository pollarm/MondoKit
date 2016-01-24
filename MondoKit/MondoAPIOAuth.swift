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

public protocol ErrorWithLocalizedFailureReason {
    
    func getLocalizedFailureReason() -> String?
}

public enum LoginError : ErrorType, ErrorWithLocalizedFailureReason {
    
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
}

extension MondoAPI {
    
    private static let AUTHRoot = "https://auth.getmondo.co.uk/"
    private static let AUTHRedirectScheme = "mondoapi"
    private static let AUTHRedirectUri = AUTHRedirectScheme + "://success"
    
    func authorizeFromCode(code : String, completion: (success: Bool, error: ErrorType?) -> Void) -> Void {
        
        let parameters = [
            "grant_type": "authorization_code",
            "client_id": clientId!,
            "client_secret": clientSecret!,
            "redirect_uri" : MondoAPI.AUTHRedirectUri,
            "code" : code
        ]
        
        Alamofire.request(.POST, MondoAPI.APIRoot+"oauth2/token", parameters: parameters).responseJSON { response in
            
            var success : Bool = false
            var anyError : ErrorType?
            
            defer {
                self.dispatchCompletion() {
                    completion(success: success, error: anyError)
                }
            }
            
            switch response.result {
                
            case .Success(let value):
                
                debugPrint(value)
                
                let json = JSON(value)
                
                if let userId = json["user_id"].string,
                    accessToken = json["access_token"].string,
                    expiresIn = json["expires_in"].int {
                        
                        let refreshToken = value["refresh_token"] as? String
                        self.authData = AuthData(userId: userId, accessToken: accessToken, expiresIn: expiresIn, refreshToken: refreshToken)
                        
                        success = true
                }
                else if let code = value["code"] as? String, message = value["message"] as? String {
                    
                    switch code {
                    case "internal_service.request_failed":
                        anyError = LoginError.RequestFailed(message)
                    case "bad_request.could_not_authenticate":
                        anyError = LoginError.CouldNotAuthenticate(message)
                    default:
                        anyError = LoginError.Other(message)
                    }
                    
                }
                else {
                    anyError = LoginError.Unknown
                }
                
            case .Failure(let error):
                
                debugPrint(error)
                anyError = error
            }
        }
        
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
