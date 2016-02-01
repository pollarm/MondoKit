//
//  CurrencyFormatter.swift
//  MondoKit
//
//  Created by Mike Pollard on 01/02/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import Foundation

struct CurrencyFormatter {
    
    let isoCode : String
    let currencySymbol : String
    let scale : Double
    
    let formatter : NSNumberFormatter
    
    init(isoCode : String) {
        
        self.isoCode = isoCode
        let locale = NSLocale.currentLocale()
        currencySymbol = locale.displayNameForKey(NSLocaleCurrencySymbol, value: isoCode) ?? "?"
        formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.CurrencyAccountingStyle
        formatter.currencySymbol = currencySymbol
        
        scale = Double(CurrencyFormatter.currencyCodeToMinorUnit[isoCode] ?? 2)
    }
    
    func stringFromMinorUnitsValue(minorUnitValue: Int) -> String? {
        return formatter.stringFromNumber(Double(minorUnitValue) / pow(10.0, scale))
    }
    
    static var currencyCodeToMinorUnit : [String:Int] = {
    
        let fileLocation = NSBundle.mainBundle().pathForResource("iso4217", ofType: "csv")!
        
        var error: NSErrorPointer = nil
        let csv = CSV(contentsOfFile: fileLocation, error: error)!
        
        var result = [String:Int]()
        for row in csv.rows {
            if let code = row["currencyCode"],
                minorUnit = row["minorUnit"],
                unitInt = Int(minorUnit) {
                    
                    result[code] = unitInt
            }
        }
        
        return result
    }()
}

//  https://github.com/naoty/SwiftCSV

//  CSV.swift
//  SwiftCSV
//
//  Created by naoty on 2014/06/09.
//  Copyright (c) 2014年 Naoto Kaneko. All rights reserved.
//
public class CSV {
    public var headers: [String] = []
    public var rows: [Dictionary<String, String>] = []
    public var columns = Dictionary<String, [String]>()
    var delimiter = NSCharacterSet(charactersInString: ",")
    
    public init?(contentsOfFile file: String, delimiter: NSCharacterSet, encoding: UInt, error: NSErrorPointer) {
        let csvString : String
        do {
            csvString = try String(contentsOfFile: file);
            let csvStringToParse = csvString
            self.delimiter = delimiter
            
            let newline = NSCharacterSet.newlineCharacterSet()
            var lines: [String] = []
            csvStringToParse.stringByTrimmingCharactersInSet(newline).enumerateLines { line, stop in lines.append(line) }
            
            self.headers = self.parseHeaders(fromLines: lines)
            self.rows = self.parseRows(fromLines: lines)
            self.columns = self.parseColumns(fromLines: lines)
        }
        catch {
            csvString = ""
        }
        
    }
    
    public convenience init?(contentsOfFile file: String, error: NSErrorPointer) {
        let comma = NSCharacterSet(charactersInString: ",")
        self.init(contentsOfFile: file, delimiter: comma, encoding: NSUTF8StringEncoding, error: error)
    }
    
    public convenience init?(contentsOfURL file: String, encoding: UInt, error: NSErrorPointer) {
        let comma = NSCharacterSet(charactersInString: ",")
        self.init(contentsOfFile: file, delimiter: comma, encoding: encoding, error: error)
    }
    
    func parseHeaders(fromLines lines: [String]) -> [String] {
        return lines[0].componentsSeparatedByCharactersInSet(self.delimiter)
    }
    
    func parseRows(fromLines lines: [String]) -> [Dictionary<String, String>] {
        var rows: [Dictionary<String, String>] = []
        
        for (lineNumber, line) in lines.enumerate() {
            if lineNumber == 0 {
                continue
            }
            
            var row = Dictionary<String, String>()
            let values = line.componentsSeparatedByCharactersInSet(self.delimiter)
            for (index, header) in self.headers.enumerate() {
                if index < values.count {
                    row[header] = values[index]
                } else {
                    row[header] = ""
                }
            }
            rows.append(row)
        }
        
        return rows
    }
    
    func parseColumns(fromLines lines: [String]) -> Dictionary<String, [String]> {
        var columns = Dictionary<String, [String]>()
        
        for header in self.headers {
            let column = self.rows.map { row in row[header] != nil ? row[header]! : "" }
            columns[header] = column
        }
        
        return columns
    }
}