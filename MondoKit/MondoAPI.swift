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
    
    // pagination is limit, since, before
    
    public func listTransactionsForAccount(account: MondoAccount, expand: String? = nil, completion: (transactions: [MondoTransaction]?, error: ErrorType?) -> Void) {
    
        assert(initialised, "MondoAPI.instance not initialised!")
        
        if let authData = authData {
            
            var parameters = ["account_id" : account.accountId]
            if let expand = expand {
                parameters["expand[]"] = expand
            }
            
            Alamofire.request(.GET, MondoAPI.APIRoot+"transactions", parameters: parameters, headers: ["Authorization":"Bearer " + authData.accessToken]).responseJSON { response in
                
                var transactions : [MondoTransaction]?
                var anyError : ErrorType?
                
                defer {
                    self.dispatchCompletion() {
                        completion(transactions: transactions, error: anyError)
                    }
                }
                
                switch response.result {
                    
                case .Success(let value):
                    debugPrint(value)
                    
                    let json = JSON(value)
                    do {
                        transactions = try json["transactions"].requiredAsArray()
                    }
                    catch {
                        debugPrint("Could not create MondoTransactions from \(json) \n Error: \(error)")
                        anyError = error
                    }
                    
                case .Failure(let error):
                    debugPrint(error)
                }

            }
        }
    }
}
/*
{
transactions =     (
{
"account_balance" = 10000;
amount = 10000;
attachments =             (
);
category = mondo;
created = "2016-01-19T18:44:13.653Z";
currency = GBP;
description = "Initial top up";
id = "tx_000094K6AMHyTYiCKsAS01";
"is_load" = 1;
"local_amount" = 10000;
"local_currency" = GBP;
merchant = "<null>";
metadata =             {
};
notes = "";
settled = "2016-01-19T18:44:13.653Z";
},
{
"account_balance" = 9937;
amount = "-63";
attachments =             (
);
category = groceries;
created = "2016-01-19T20:08:52.193Z";
currency = GBP;
description = "TESCO STORES 5371      ASHTEAD       GBR";
id = "tx_000094KDihIfYw1i5BvGOf";
"is_load" = 0;
"local_amount" = "-63";
"local_currency" = GBP;
merchant = "merch_000094KDihVmm9zgP75onp";
metadata =             {
notes = "M&Ms \Ud83c\Udf6b";
};
notes = "M&Ms \Ud83c\Udf6b";
settled = "2016-01-20T09:12:34.64Z";
},
{
"account_balance" = 9726;
amount = "-211";
attachments =             (
{
created = "2016-01-20T09:26:55.298Z";
id = "attach_000094LMwUpVohVV9Kn3fl";
type = "image/jpeg";
url = "https://s3-eu-west-1.amazonaws.com/mondo-production-image-uploads/user_000094K2gKd7mNdBhK9xsf/wQkBarAx31jhzZSKS2rq-66AC6758-D64C-46CC-AA50-0A8E09E64E21.jpg";
}
);
category = groceries;
created = "2016-01-20T09:12:33.777Z";
currency = GBP;
description = "WAITROSE LTD           LONDON        GBR";
id = "tx_000094LLf3DH8rOaWTSQAz";
"is_load" = 0;
"local_amount" = "-211";
"local_currency" = GBP;
merchant = "merch_000094LLf3Q2NPjnyu8V8L";
metadata =             {
notes = Breakfast;
};
notes = Breakfast;
settled = "2016-01-21T09:13:29.323Z";
},
{
"account_balance" = 9241;
amount = "-485";
attachments =             (
{
created = "2016-01-20T16:58:20.34Z";
id = "attach_000094M1EIIT9INTYnoK2r";
type = "image/jpeg";
url = "https://s3-eu-west-1.amazonaws.com/mondo-production-image-uploads/user_000094K2gKd7mNdBhK9xsf/go5SN6cQvJoXSrAW3sku-478A0359-F252-4829-A993-3AADB1324167.jpg";
}
);
category = groceries;
created = "2016-01-20T13:05:44.507Z";
currency = GBP;
description = "SAINSBURYS SACAT 0016  WIMBLEDON     GBR";
id = "tx_000094LgTGdhUnyRj42Xg1";
"is_load" = 0;
"local_amount" = "-485";
"local_currency" = GBP;
merchant = "merch_000094LgTGqSjMyMoCjAwr";
metadata =             {
notes = Lunch;
};
notes = Lunch;
settled = "2016-01-21T00:00:00.5Z";
},
{
"account_balance" = 9030;
amount = "-211";
attachments =             (
);
category = groceries;
created = "2016-01-21T09:13:28.443Z";
currency = GBP;
description = "WAITROSE LTD           LONDON        GBR";
id = "tx_000094NQFyCxVAkagsGX3Z";
"is_load" = 0;
"local_amount" = "-211";
"local_currency" = GBP;
merchant = "merch_000094LLf3Q2NPjnyu8V8L";
metadata =             {
};
notes = "";
settled = "2016-01-22T09:43:34.5Z";
},
{
"account_balance" = 7230;
amount = "-1800";
attachments =             (
{
created = "2016-01-21T15:14:36.322Z";
id = "attach_000094NwUAUDqRfEpifbov";
type = "image/jpeg";
url = "https://s3-eu-west-1.amazonaws.com/mondo-production-image-uploads/user_000094K2gKd7mNdBhK9xsf/WPqPlO7HeOOGXdEhfTdq-E266B9E1-9644-4244-A070-5E9CD7C87127.jpg";
}
);
category = "eating_out";
created = "2016-01-21T13:12:58.28Z";
currency = GBP;
description = "PIZZA EXPRESS          LONDON        GBR";
id = "tx_000094Nld8LE5fayf7wuVV";
"is_load" = 0;
"local_amount" = "-1800";
"local_currency" = GBP;
merchant = "merch_000094Nld8XzKEd3vfVPOL";
metadata =             {
};
notes = "";
settled = "2016-01-22T09:43:35Z";
},
{
"account_balance" = 7005;
amount = "-225";
attachments =             (
{
created = "2016-01-22T14:19:15.161Z";
id = "attach_000094Pw3kGh5cE4J1f9lJ";
type = "image/jpeg";
url = "https://s3-eu-west-1.amazonaws.com/mondo-production-image-uploads/user_000094K2gKd7mNdBhK9xsf/svmUySkqcoviqnk9C1mD-6F486EA7-BA82-4A4C-94D8-8E29AB74DB10.jpg";
}
);
category = groceries;
created = "2016-01-22T09:43:33.553Z";
currency = GBP;
description = "GREGGS-WIMBLEDON       LONDON  SW19  GBR";
id = "tx_000094PXSHR8vJNHnWdYnp";
"is_load" = 0;
"local_amount" = "-225";
"local_currency" = GBP;
merchant = "merch_000094PXSHi9u3rRXxpRI1";
metadata =             {
notes = Breakfast;
};
notes = Breakfast;
settled = "";
},
{
"account_balance" = 7005;
amount = "-409";
attachments =             (
);
category = groceries;
created = "2016-01-22T14:17:14.05Z";
currency = GBP;
"decline_reason" = OTHER;
description = "WM MORRISONS STORE     LONDON        GBR";
id = "tx_000094PvsZKzOBs1kFpKr3";
"is_load" = 0;
"local_amount" = "-409";
"local_currency" = GBP;
merchant = "merch_000094DjrAZQSPQ4tbAPQn";
metadata =             {
};
notes = "";
settled = "";
},
{
"account_balance" = 7005;
amount = "-409";
attachments =             (
);
category = groceries;
created = "2016-01-22T14:17:38.79Z";
currency = GBP;
"decline_reason" = OTHER;
description = "WM MORRISONS STORE     LONDON        GBR";
id = "tx_000094PvuqhXnniNeRynyb";
"is_load" = 0;
"local_amount" = "-409";
"local_currency" = GBP;
merchant = "merch_000094DjrAZQSPQ4tbAPQn";
metadata =             {
};
notes = "";
settled = "";
},
{
"account_balance" = 5775;
amount = "-1230";
attachments =             (
);
category = "eating_out";
created = "2016-01-22T19:14:47.213Z";
currency = GBP;
description = "ALEXANDRA              LONDON        GBR";
id = "tx_000094QMR1WXhHSWfCFc13";
"is_load" = 0;
"local_amount" = "-1230";
"local_currency" = GBP;
merchant = "merch_000094QMR1lmmcPI1xAa0n";
metadata =             {
notes = "\Ud83c\Udf7a";
};
notes = "\Ud83c\Udf7a";
settled = "";
},
{
"account_balance" = 4545;
amount = "-1230";
attachments =             (
);
category = "eating_out";
created = "2016-01-22T21:28:18.283Z";
currency = GBP;
description = "ALEXANDRA              LONDON        GBR";
id = "tx_000094QYLnhEsYmAPP7Ds1";
"is_load" = 0;
"local_amount" = "-1230";
"local_currency" = GBP;
merchant = "merch_000094QMR1lmmcPI1xAa0n";
metadata =             {
notes = "\Ud83c\Udf7a";
};
notes = "\Ud83c\Udf7a";
settled = "";
},
{
"account_balance" = 4189;
amount = "-356";
attachments =             (
{
created = "2016-01-23T17:17:32.297Z";
id = "attach_000094SGU66itwEVt2GzhZ";
type = "image/jpeg";
url = "https://s3-eu-west-1.amazonaws.com/mondo-production-image-uploads/user_000094K2gKd7mNdBhK9xsf/ChcSLk8sWRdjwHooCpeJ-3709C982-B609-488C-AA03-BFC6A34DBFEB.jpg";
}
);
category = groceries;
created = "2016-01-23T14:04:02.11Z";
currency = GBP;
description = "TESCO STORES 5371      ASHTEAD       GBR";
id = "tx_000094RzDNcGqtpcY9fxKr";
"is_load" = 0;
"local_amount" = "-356";
"local_currency" = GBP;
merchant = "merch_000094KDihVmm9zgP75onp";
metadata =             {
};
notes = "";
settled = "";
}
);
}

*/