//
//  AST.swift
//  MakeMathML
//
//  Created by Mike Griebling on 13 Aug 2017.
//  Copyright © 2017 Computer Inspirations. All rights reserved.
//

import Foundation

public enum Type { case UNDEF, INT, BOOL }
public enum Operator { case EQU, LSS, GTR, GEQ, LEQ, NEQ, ADD, SUB, MUL, DIV, REM, OR, AND, NOT, POW, FACT, SQR, CUB }

public class Node {            // base node class of the AST
    public init() {}
    public func dump() {}
    func printn(_ s: String) { print(s, terminator: "") }
    var value: Double { return 0 }
    var mathml: String { return "" }
}


//----------- Declarations ----------------------------



public class Obj : Node {      // any declared object that has a name
    var name: String    // name of this object
    var type: Type      // type of the object (UNDEF for procedures)
    var val: Expr?
    init(_ s: String, _ t: Type) { name = s; type = t }
}

public class Var : Obj {       // variables
    var adr: Int = 0    // address in memory
    override init(_ name: String, _ type: Type) { super.init(name, type) }
}

public class BuiltInProc : Expr {
    
    static var _builtIns : [String: (_:Double) -> Double] = [
        "sin"  : sin,
        "cos"  : cos,
        "tan"  : tan,
        "asin" : asin,
        "acos" : acos,
        "atan" : atan,
        "sinh" : sinh,
        "cosh" : cosh,
        "tanh" : tanh,
        "asinh": asinh,
        "acosh": acosh,
        "atanh": atanh,
        "exp"  : exp,
        "ln"   : log,
        "log"  : log10,
        "log10": log10,
        "abs"  : abs,
        "sqrt" : sqrt,
        "cbrt" : cbrt
    ]
    
    var op: (_:Double) -> Double
    var arg: Expr?
    var name: String
    
    init(_ name: String, _ arg: Expr?) { op = BuiltInProc._builtIns[name] ?? { _ in 0 }; self.name = name; self.arg = arg; super.init() }
    override func dump() { printn("Built-in " + name + "("); arg?.dump(); printn(")") }
    override var value: Double { return op(Double(arg?.value ?? 0)) }
    
    override var mathml: String {
        let x = arg?.mathml ?? ""
        var s = ""
        switch name {
        case "sqrt": return root(x, n: 2)
        case "cbrt": return root(x, n: 3)
        case "abs": return  fenced(x, open: "|", close: "|")
        case "exp": return power(variable("e"), to: x)
        case "log", "log10": s += "<msub>\n\(variable("log"))\(number(10))</msub>\n"
        default: s += variable(name)
        }
        return s + fenced(x)
    }
}

public class Proc : Obj {      // procedure (also used for the main program)
    var locals: [Obj]   // local objects declared in this procedure
    var block: Block?   // block of this procedure (nil for the main program)
    var nextAdr = 0     // next free address in this procedure
    var program: Proc?  // link to the Proc node of the main program or nil
    var parser: Parser  // for error messages
    
   	init (_ name: String, _ program: Proc?, _ parser: Parser) {
        locals = [Obj]()
        self.program = program
        self.parser = parser
        super.init(name, .UNDEF)
    }
    
    func add (_ obj: Obj) {
        for o in locals {
            if o.name == obj.name { parser.SemErr(obj.name + " declared twice") }
        }
        locals.append(obj)
        if obj is Var { (obj as! Var).adr = nextAdr; nextAdr += 1 }
    }
    
    func find (_ name: String) -> Obj {
        for o in locals { if o.name == name { return o } }
        if program != nil { for o in program!.locals { if o.name == name { return o } } }
        let o = Obj(name, .INT) // declare a default name
        add(o)
        return o
    }
    
    override public func dump() {
        print("Proc " + name); block?.dump(); print()
    }
    
    override var mathml: String {
        return block?.mathml ?? ""
    }
}

//----------- Expressions ----------------------------

public class Expr : Node {}

public class BinExpr: Expr {
    var op: Operator
    var left, right: Expr?
    
    public init(_ e1: Expr?, _ o: Operator, _ e2: Expr?) { op = o; left = e1; right = e2 }
    public override func dump() { printn("("); left?.dump(); printn(" \(op) "); right?.dump(); printn(")") }
    public override var value: Double {
        let l = left?.value ?? 0
        let r = right?.value ?? 0
        switch op {
        case .ADD: return l + r
        case .SUB: return l - r
        case .MUL: return l * r
        case .DIV: return l / r
        case .REM: return Double(Int(l) % Int(r))
        case .AND: return Double(Int(l) & Int(r))
        case .OR:  return Double(Int(l) | Int(r))
        case .POW: return pow(l, r)
        case .EQU: return l == r ? 1 : 0
        case .LSS: return l <  r ? 1 : 0
        case .GTR: return l >  r ? 1 : 0
        case .LEQ: return l <= r ? 1 : 0
        case .GEQ: return l >= r ? 1 : 0
        case .NEQ: return l != r ? 1 : 0
        default: return 0  // shouldn't occur
        }
    }
    
    override var mathml: String {
        var s = ""
        let l = left?.mathml ?? ""
        let r = right?.mathml ?? ""
        switch op {
        case .ADD: s = symbol("+")
        case .SUB: s = symbol("-")
        case .MUL: s = symbol("") // invisible times
        case .DIV: return fraction(l, over: r)
        case .REM: s = symbol("%")
        case .AND: s = symbol("&amp;")
        case .OR:  s = symbol("|")
        case .POW: return power(l, to:r)
        case .EQU: s = symbol("=")
        case .LSS: s = symbol("&lt;")
        case .GTR: s = symbol("&gt;")
        case .LEQ: s = symbol("&le;")
        case .GEQ: s = symbol("&ge;")
        case .NEQ: s = symbol("&ne;")
        default: break
        }
        return l + s + r
    }
}

public class UnaryExpr: Expr {
    var op: Operator
    var e: Expr?
    
    public init(_ x: Operator, _ y: Expr?) { op = x; e = y }
    public override func dump() { printn("\(op) "); e?.dump() }
    
    public override var value: Double {
        let x = e?.value ?? 0
        switch op {
        case .SUB: return -x
        case .NOT: return Double(~Int(x))
        case .SQR: return x*x
        case .CUB: return x*x*x
        case .FACT: return tgamma(x+1)
        default: return x
        }
    }
    
    override var mathml: String {
        let x = e?.mathml ?? ""
        var s = ""
        switch op {
        case .SUB: s = symbol("-")
        case .NOT: s = symbol("~")
        case .SQR: return power(x, to:number(2))
        case .CUB: return power(x, to:number(3))
        case .FACT: return x + symbol("!")
        default: break
        }
        return s + x
    }
}

public class Ident: Expr {
    var obj: Obj

    init(_ o: Obj) { obj = o }
    override func dump() { printn(obj.name) }
    override var value: Double { return obj.val?.value ?? 0 }
    override var mathml: String {
        return variable(obj.name)
    }
}

public class IntCon: Expr {
    var val: Double
    
    init(_ x:Double) { val = x }
    override func dump() { printn("\(val)") }
    override var value: Double { return val }
    override var mathml: String {
        return number(val)
    }
}

public class BoolCon: Expr {
    var val: Bool
    
    init(_ x: Bool) { val = x }
    override func dump() { printn("\(val)") }
    override var value: Double { return val ? 1 : 0 }
    override var mathml: String {
        return symbol("\(val)")
    }
}

//------------- Statements -----------------------------

public class Stat: Node {
    static var indent = 0
    override public func dump() { for _ in 0..<Stat.indent { printn("  ") } }
}

public class Assignment: Stat {
    var left: Obj?
    var right: Expr?
    
    init(_ o:Obj?, _ e:Expr?) { left = o; left?.val = e; right = e }
    override public func dump() { super.dump(); if left != nil { printn(left!.name + " = ") }; right?.dump() }
    override public var value: Double { return right?.value ?? 0 }
    
    override var mathml: String {
        let e = right?.mathml ?? ""
        let l = left?.name ?? ""
        var x = "<mrow>\n"
        if !l.isEmpty {
            x += variable(l) + symbol("=")
        }
        return x + e + "</mrow>\n"
    }
}

public class Block: Stat {
    var stats = [Stat]()
    
    func add(_ s: Stat?) { if s != nil { stats.append(s!) } }
    
    override public func dump() {
        super.dump()
        print("Block("); Stat.indent+=1
        for s in stats { s.dump(); print("  => \(s.value)") }
        Stat.indent-=1; super.dump(); print(")")
    }
    
    override var mathml: String {
        var r = "<!DOCTYPE html>\n<html>\n<body>\n"
        for s in stats { r += "<p><math>\n" + s.mathml + "</math></p>\n\n" }
        return r + "</html>\n</body>\n"
    }
}

