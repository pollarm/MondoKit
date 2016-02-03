//
//  MondoCategory.swift
//  MondoKit
//
//  Created by Mike Pollard on 26/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftyJSONDecodable

public enum MondoCategory : String {
    case Mondo = "mondo"
    case General = "general"
    case EatingOut = "eating_out"
    case Expenses = "expenses"
    case Transport = "transport"
    case Cash = "cash"
    case Bills = "bills"
    case Entertainment = "entertainment"
    case Shopping = "shopping"
    case Holidays = "holidays"
    case Groceries = "groceries"
}

extension MondoCategory : SwiftyJSONDecodable { }
