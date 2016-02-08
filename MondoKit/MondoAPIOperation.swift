//
//  MondoAPIOperation.swift
//  MondoKit
//
//  Created by Mike Pollard on 06/02/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

/**
 Packaging API calls as `NSOperation`s will allow MondoKit to more easily manage concurrency and potential dependencies between calls.
*/
class MondoAPIOperation: NSOperation {

    typealias ResponseHandler = (json: JSON?, error: ErrorType?) -> Void
    
    private var _executing : Bool = false {
        willSet {
            willChangeValueForKey("isExecuting")
        }
        didSet {
            didChangeValueForKey("isExecuting")
        }
    }
    
    private var _finished : Bool = false {
        willSet {
            willChangeValueForKey("isFinished")
        }
        didSet {
            didChangeValueForKey("isFinished")
        }
    }
    
    override var executing: Bool { return _executing }
    override var finished: Bool { return _finished }
    override var asynchronous: Bool { return true }
    
    override func start() {
        
        guard !self.cancelled else {
            _executing = false
            _finished = true
            return
        }
        
        _executing = true
        
        request = MondoAPI.instance.alamofireManager.request(method, urlString, parameters: parameters, headers: authHeader?())
        
        request!.resume()
        
        request!.response(queue: MondoAPIOperation.ResponseQueue, responseSerializer: Request.JSONResponseSerializer()) { [unowned self] response in
        
            guard !self.cancelled else {
                self._executing = false
                self._finished = true
                return
            }
            
            var json : JSON?
            var anyError : ErrorType?
            
            defer {
                self.responseHandler(json: json, error: anyError)
                self._executing = false
                self._finished = true
            }
            
            guard let status = response.response?.statusCode where status == 200 else {
                
                debugPrint(response)
                anyError = self.errorFromResponse(response)
                return
            }
            
            switch response.result {
                
            case .Success(let value):
                
                debugPrint(value)
                json = JSON(value)
                
            case .Failure(let error):
                
                debugPrint(error)
                anyError = error
            }
            
        }
        
    }
    
    private static let ResponseQueue : dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
    
    private var method : Alamofire.Method
    private var urlString : URLStringConvertible
    private var parameters : [String : AnyObject]?
    private var authHeader: (()->[String:String]?)?
    
    private var request : Alamofire.Request?
    private var responseHandler : ResponseHandler
    
    init(method: Alamofire.Method, urlString: URLStringConvertible,
        parameters: [String : AnyObject]? = nil,
        authHeader: ()->[String:String]? = { return nil },
        responseHandler: ResponseHandler) {
        
            self.method = method
            self.urlString = urlString
            self.parameters = parameters
            self.authHeader = authHeader
            self.responseHandler = responseHandler
    }

    private func errorFromResponse(response: Alamofire.Response<AnyObject, NSError>) -> ErrorType {
        
        switch response.result {
            
        case .Success(let value):
            
            let json = JSON(value)
            return MondoAPIError.apiErrorfromJson(json)
        case .Failure(let error):
            return error
        }
    }
}
