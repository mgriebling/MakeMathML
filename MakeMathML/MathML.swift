//
//  MathML.swift
//  MakeMathML
//
//  Created by Mike Griebling on 13 Aug 2017.
//  Copyright © 2017 Computer Inspirations. All rights reserved.
//

import Foundation

extension Node {
    
    // mathml constructors
    
    func symbol(_ x: String, size: Int = 0) -> String {
        let s = size == 0 ? "" : " mathsize=\"\(size)\""
        return "<mo\(s)>\(x)</mo>\n"
    }
    
    func variable(_ x: String, size: Int = 0) -> String {
        let s = size == 0 ? "" : " mathsize=\"\(size)\""
        return "<mi\(s)>\(x)</mi>\n"
    }
    
    func number(_ val: Double, size: Int = 0) -> String {
        var v = String(val)
        if v.hasSuffix(".0") { v = v.replacingOccurrences(of: ".0", with: "") }
        let s = size == 0 ? "" : " mathsize=\"\(size)\""
        return "<mn\(s)>\(v)</mn>\n"
    }
    
    func power(_ x: String, to y: String) -> String {
        return "<msup>\n\(x)\(y)</msup>\n"
    }
    
    func fraction(_ x: String, over y: String) -> String {
        return "<mfrac>\n\(x)\(y)</mfrac>\n"
    }
    
    func root(_ x: String, n: Int) -> String {
        if n == 2 {
            return "<msqrt>\n\(x)</msqrt>\n"
        } else {
            return "<mroot><mrow>\n\(x)</mrow>\n\(number(Double(n)))</mroot>\n"
        }
    }
    
    func isComplex(_ x: String) -> Bool {
        return x.contains("<mfrac>") || x.contains("<msup>") || x.contains("<msqrt>") || x.contains("<mroot>") ||
               x.contains("<mrow>")
    }
    
    func fenced(_ x: String, open: String = "(", close: String = ")") -> String {
        var braces = ""
        if isComplex(x) {
            if open != "(" || close != ")" {
                braces = " open=\"\(open)\" close=\"\(close)\""
            }
            return "<mfenced\(braces)>\n<mrow>\(x)</mrow></mfenced>\n"
        } else {
            return symbol(open) + x + symbol(close) + "\n"
        }
    }
    
}

public class MathML {
    
    var presentation: String = ""
    var semantic: String = ""
    
    public init(_ equation: String) {
        
    }
    
    
}
