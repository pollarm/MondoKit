//
//  MondoAPIOAuth.swift
//  MondoKit
//
//  Created by Mike Pollard on 23/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation


class OAuthViewController : UIViewController {
    
    private var webView : UIWebView!
    
    private var clientId : String
    
    private var onCompletion : (success : Bool, error : LoginError?) -> Void
    
    private var state : String?
    
    init(clientId : String, onCompletion : (success : Bool, error : LoginError?) -> Void) {
        
        self.clientId = clientId
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
            
            var url = MondoAPI.AUTHRoot + "?client_id=" + clientId
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
                
                //callback
                //dismiss
                
                MondoAPI.instance.authorizeFromCode(code, completion: onCompletion)
                
                return false
            }
        }
        
        return true

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
