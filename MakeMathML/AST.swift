//
//  AST.swift
//  MakeMathML
//
//  Created by Mike Griebling on 13 Aug 2017.
//  Copyright © 2017 Computer Inspirations. All rights reserved.
//

import Foundation

enum Type { case UNDEF, INT, BOOL }
enum Operator { case EQU, LSS, GTR, GEQ, LEQ, NEQ, ADD, SUB, MUL, DIV, REM, OR, AND, NOT, POW, FACT, SQR, CUB }

class Node {            // base node class of the AST
    init() {}
    func dump() {}
    func printn(_ s: String) { print(s, terminator: "") }
    var value: Double { return 0 }
    var mathml: String { return "" }
}

//----------- Declarations ----------------------------



class Obj : Node {      // any declared object that has a name
    var name: String    // name of this object
    var type: Type      // type of the object (UNDEF for procedures)
    var val: Expr?
    init(_ s: String, _ t: Type) { name = s; type = t }
}

class Var : Obj {       // variables
    var adr: Int = 0    // address in memory
    override init(_ name: String, _ type: Type) { super.init(name, type) }
}

class BuiltInProc : Expr {
    
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
        var s = "<mi>"
        switch name {
        case "sqrt": return "<msqrt>\n\(x)</msqrt>\n"
        case "cbrt": return "<mroot>\n\(x)<mn>3</mn>\n</mroot>\n"
        case "abs": return "<ms>|</ms>" + x + "<ms>|</ms>"
        default: s += name + "</mi>"
        }
        return s + "<ms>(</ms>" + x + "<ms>)</ms>"
    }
}

class Proc : Obj {      // procedure (also used for the main program)
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
    
    override func dump() {
        print("Proc " + name); block?.dump(); print()
    }
}

//----------- Expressions ----------------------------

class Expr : Node {}

class BinExpr: Expr {
    var op: Operator
    var left, right: Expr?
    
    init(_ e1: Expr?, _ o: Operator, _ e2: Expr?) { op = o; left = e1; right = e2 }
    override func dump() { printn("("); left?.dump(); printn(" \(op) "); right?.dump(); printn(")") }
    override var value: Double {
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
        var s = "<mo>"
        let l = left?.mathml ?? ""
        let r = right?.mathml ?? ""
        switch op {
        case .ADD: s += "+"
        case .SUB: s += "-"
        case .MUL: s += "" // invisible multiply
        case .DIV: return "<mfrac>\n\(l)\(r)</mfrac>"
        case .REM: s += "%"
        case .AND: s += "&"
        case .OR:  s += "|"
        case .POW: s += "^"
        case .EQU: s += "="
        case .LSS: s += "<"
        case .GTR: s += ">"
        case .LEQ: s += "<="
        case .GEQ: s += ">="
        case .NEQ: s += "!="
        default: break
        }
        s += "</mo>\n"
        return l + s + r
    }
}

class UnaryExpr: Expr {
    var op: Operator
    var e: Expr?
    
    init(_ x: Operator, _ y: Expr?) { op = x; e = y }
    override func dump() { printn("\(op) "); e?.dump() }
    
    override var value: Double {
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
        var s = "<mo>"
        switch op {
        case .SUB: s += "-"
        case .NOT: s += "~"
        case .SQR: return "<msup>\n\(x)\n<mn>2</mn>\n</msup>\n"
        case .CUB: return "<msup>\n\(x)\n<mn>3</mn>\n</msup>\n"
        case .FACT: return x + s + "!</mo>"
        default: break
        }
        return s + "</mo>" + x
    }
}

class Ident: Expr {
    var obj: Obj

    init(_ o: Obj) { obj = o }
    override func dump() { printn(obj.name) }
    override var value: Double { return obj.val?.value ?? 0 }
    override var mathml: String {
        return "<mi>\(obj.name)</mi>\n"
    }
}

class IntCon: Expr {
    var val: Double
    
    init(_ x:Double) { val = x }
    override func dump() { printn("\(val)") }
    override var value: Double { return val }
    override var mathml: String {
        return "<mn>\(val)</mn>\n"
    }
}

class BoolCon: Expr {
    var val: Bool
    
    init(_ x: Bool) { val = x }
    override func dump() { printn("\(val)") }
    override var value: Double { return val ? 1 : 0 }
    override var mathml: String {
        return "<mn>\(val)</mn>\n"
    }
}

//------------- Statements -----------------------------

class Stat: Node {
    static var indent = 0
    override func dump() { for _ in 0..<Stat.indent { printn("  ") } }
}

class Assignment: Stat {
    var left: Obj?
    var right: Expr?
    
    init(_ o:Obj?, _ e:Expr?) { left = o; left?.val = e; right = e }
    override func dump() { super.dump(); if left != nil { printn(left!.name + " = ") }; right?.dump() }
    override var value: Double { return right?.value ?? 0 }
    
    override var mathml: String {
        let e = right?.mathml ?? ""
        let l = left?.mathml ?? ""
        var x = "<mrow>\n"
        if !l.isEmpty {
            x += "\(l)<mo>=</mo>\n"
        }
        return x + e + "</mrow>\n"
    }
}

//class Call: Stat {
//    var proc:Obj
//    init(_ o:Obj) { proc = o }
//    override func dump() { super.dump(); print("call " + proc.name) }
//}
//
//class If: Stat {
//    var cond:Expr
//    var stat:Stat
//    init(_ e:Expr, _ s:Stat) { cond = e; stat = s }
//    override func dump() { super.dump(); printn("if "); cond.dump(); print(); Stat.indent+=1; stat.dump(); Stat.indent-=1 }
//}
//
//class IfElse: Stat {
//    var ifPart: Stat
//    var elsePart: Stat?
//    init(_ i:Stat, _ e:Stat?) { ifPart = i; elsePart = e }
//    override func dump() { ifPart.dump(); super.dump(); print("else "); Stat.indent+=1; elsePart?.dump(); Stat.indent-=1 }
//}
//
//class While: Stat {
//    var cond: Expr
//    var stat: Stat
//    init(_ e:Expr, _ s:Stat) { cond = e; stat = s }
//    override func dump() { super.dump(); printn("while "); cond.dump(); print(); Stat.indent+=1; stat.dump(); Stat.indent-=1 }
//}
//
//class Read: Stat {
//    var obj:Obj
//    init(_ o:Obj) { obj = o }
//    override func dump() { super.dump(); print("read " + obj.name) }
//}
//
//class Write: Stat {
//    var e:Expr
//    init(_ x:Expr) { e = x }
//    override func dump() { super.dump(); printn("write "); e.dump(); print() }
//}

class Block: Stat {
    var stats = [Stat]()
    
    func add(_ s: Stat?) { if s != nil { stats.append(s!) } }
    
    override func dump() {
        super.dump()
        print("Block("); Stat.indent+=1
        for s in stats { s.dump(); print("  => \(s.value)") }
        Stat.indent-=1; super.dump(); print(")")
    }
    
    override var mathml: String {
        var r = "<math>\n"
        for s in stats { r += s.mathml }
        return r + "</math>\n"
    }
}

