/*-------------------------------------------------------------------------
    Compiler Generator Coco/R,
    Copyright (c) 1990, 2004 Hanspeter Moessenboeck, University of Linz
    extended by M. Loeberbauer & A. Woess, Univ. of Linz
    with improvements by Pat Terry, Rhodes University
    Swift port by Michael Griebling, 2015-2017

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation; either version 2, or (at your option) any
    later version.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

    As an exception, it is allowed to write an extension of Coco/R that is
    used as a plugin in non-free software.

    If not otherwise stated, any source code generated by Coco/R (other than
    Coco/R itself) does not fall under the GNU General Public License.

    NOTE: The code below has been automatically generated from the
    Parser.frame, Scanner.frame and Coco.atg files.  DO NOT EDIT HERE.
-------------------------------------------------------------------------*/

import Foundation



public class Parser {
	public let _EOF = 0
	public let _squared = 1
	public let _cubed = 2
	public let _times = 3
	public let _divide = 4
	public let _minus = 5
	public let _ident = 6
	public let _number = 7
	public let _octalInt = 8
	public let _hexInt = 9
	public let _binInt = 10
	public let _decInt = 11
	public let _baseInt = 12
	public let _let = 14
	public let _true = 20
	public let _false = 21
	public let maxT = 37

	static let _T = true
	static let _x = false
	static let minErrDist = 2
	let minErrDist : Int = Parser.minErrDist

	public var scanner: Scanner
	public var errors: Errors

	public var t: Token             // last recognized token
	public var la: Token            // lookahead token
	var errDist = Parser.minErrDist

	var curBlock: Proc!  // current program unit (procedure or main program)
	
	


    public init(scanner: Scanner) {
        self.scanner = scanner
        errors = Errors()
        t = Token()
        la = t
    }
    
    func SynErr (_ n: Int) {
        if errDist >= minErrDist { errors.SynErr(la.line, col: la.col, n: n) }
        errDist = 0
    }
    
    public func SemErr (_ msg: String) {
        if errDist >= minErrDist { errors.SemErr(t.line, col: t.col, s: msg) }
        errDist = 0
    }

	func Get () {
		while true {
            t = la
            la = scanner.Scan()
            if la.kind <= maxT { errDist += 1; break }

			la = t
		}
	}
	
    func Expect (_ n: Int) {
        if la.kind == n { Get() } else { SynErr(n) }
    }
    
    func StartOf (_ s: Int) -> Bool {
        return set(s, la.kind)
    }
    
    func ExpectWeak (_ n: Int, _ follow: Int) {
        if la.kind == n {
			Get()
		} else {
            SynErr(n)
            while !StartOf(follow) { Get() }
        }
    }
    
    func WeakSeparator(_ n: Int, _ syFol: Int, _ repFol: Int) -> Bool {
        var kind = la.kind
        if kind == n { Get(); return true }
        else if StartOf(repFol) { return false }
        else {
            SynErr(n)
            while !(set(syFol, kind) || set(repFol, kind) || set(0, kind)) {
                Get()
                kind = la.kind
            }
            return StartOf(syFol)
        }
    }

	func Program() {
		curBlock = Proc("", nil, self); curBlock.block = Block() 
		BlockList(curBlock.block)
		curBlock.dump()
		let x = curBlock.mathml
		if let f = OutputStream(toFileAtPath: "test.html", append: false), let d = x.data(using: .utf8) {
		  f.open()
		  let bytes = [UInt8](d)
		  f.write(bytes, maxLength: bytes.count)
		  print("\n\n\(x)")
		  f.close()
		}
		
	}

	func BlockList(_ b: Block?) {
		var s: Stat? = nil 
		Statement(&s)
		b?.add(s) 
		while la.kind == 13 /* ";" */ {
			Get()
			Statement(&s)
			b?.add(s) 
		}
	}

	func Statement(_ s: inout Stat?) {
		var e: Expr? = nil; var name = ""; var obj : Obj? = nil 
		s = nil 
		if la.kind == _let {
			Get()
			Expect(_ident)
			name = t.val; obj = curBlock.find(name)
			if Ident._symbols[name] != nil { SemErr("Can't assign to a reserved symbol \"\(name)\"") }
			
			Expect(15 /* "=" */)
		}
		Expression(&e)
		s = Assignment(obj, e) 
	}

	func Expression(_ e: inout Expr?) {
		var e2: Expr? = nil; var op = Operator.EQU 
		SimpleExpression(&e)
		if StartOf(1) {
			RelOp(&op)
			SimpleExpression(&e2)
			e = BinExpr(e, op, e2) 
		}
	}

	func SimpleExpression(_ e: inout Expr?) {
		var e2: Expr? = nil; var op = Operator.EQU 
		Term(&e)
		while StartOf(2) {
			AddOp(&op)
			Term(&e2)
			e = BinExpr(e, op, e2) 
		}
	}

	func RelOp(_ op: inout Operator) {
		op = .EQU 
		switch la.kind {
		case 31 /* "==" */: 
			Get()
		case 32 /* "!=" */: 
			Get()
			op = .NEQ 
		case 33 /* "<=" */: 
			Get()
			op = .LEQ 
		case 34 /* "<" */: 
			Get()
			op = .LSS 
		case 35 /* ">" */: 
			Get()
			op = .GTR 
		case 36 /* ">=" */: 
			Get()
			op = .GEQ 
		default: SynErr(38)
		}
	}

	func Term(_ e: inout Expr?) {
		var e2: Expr? = nil; var op = Operator.EQU 
		Power(&e)
		while StartOf(3) {
			MulOp(&op)
			Power(&e2)
			e = BinExpr(e, op, e2) 
		}
	}

	func AddOp(_ op: inout Operator) {
		op = .ADD 
		if la.kind == 22 /* "+" */ {
			Get()
		} else if la.kind == 18 /* "-" */ {
			Get()
			op = .SUB 
		} else if la.kind == _minus {
			Get()
			op = .SUB 
		} else if la.kind == 23 /* "|" */ {
			Get()
			op = .OR  
		} else { SynErr(39) }
	}

	func Power(_ e: inout Expr?) {
		var e2: Expr? = nil; var op = Operator.EQU 
		Factor(&e)
		while la.kind == 29 /* "^" */ || la.kind == 30 /* "**" */ {
			PowerOp(&op)
			Factor(&e2)
			e = BinExpr(e, op, e2) 
		}
	}

	func MulOp(_ op: inout Operator) {
		op = .MUL 
		switch la.kind {
		case 24 /* "*" */: 
			Get()
		case _times: 
			Get()
		case _divide: 
			Get()
			op = .DIV 
		case 25 /* "/" */: 
			Get()
			op = .DIV 
		case 26 /* "%" */: 
			Get()
			op = .REM 
		case 27 /* "&" */: 
			Get()
			op = .AND 
		default: SynErr(40)
		}
	}

	func Factor(_ e: inout Expr?) {
		var name = ""; var op = Operator.EQU 
		switch la.kind {
		case _ident: 
			e = nil 
			Get()
			name = t.val; e = Ident(curBlock.find(name)) 
			if StartOf(4) {
				if la.kind == _squared || la.kind == _cubed || la.kind == 28 /* "!" */ {
					UnaryOp(&op)
					e = UnaryExpr(op, e) 
				} else {
					Get()
					Expression(&e)
					e = BuiltInProc(name, e) 
					Expect(17 /* ")" */)
				}
			}
		case _number: 
			Get()
			e = IntCon(Double(t.val) ?? 0) 
			if la.kind == _squared || la.kind == _cubed || la.kind == 28 /* "!" */ {
				UnaryOp(&op)
				e = UnaryExpr(op, e) 
			}
		case 18 /* "-" */: 
			Get()
			Factor(&e)
			e = UnaryExpr(Operator.SUB, e) 
		case 19 /* "~" */: 
			Get()
			Factor(&e)
			e = UnaryExpr(Operator.NOT, e) 
		case _true: 
			Get()
			e = BoolCon(true) 
		case _false: 
			Get()
			e = BoolCon(false) 
		case 16 /* "(" */: 
			Get()
			Expression(&e)
			Expect(17 /* ")" */)
		default: SynErr(41)
		}
	}

	func PowerOp(_ op: inout Operator) {
		op = .POW 
		if la.kind == 29 /* "^" */ {
			Get()
		} else if la.kind == 30 /* "**" */ {
			Get()
			op = .POW 
		} else { SynErr(42) }
	}

	func UnaryOp(_ op: inout Operator) {
		op = .FACT 
		if la.kind == 28 /* "!" */ {
			Get()
		} else if la.kind == _squared {
			Get()
			op = .SQR 
		} else if la.kind == _cubed {
			Get()
			op = .CUB 
		} else { SynErr(43) }
	}



    public func Parse() {
        la = Token()
        la.val = ""
        Get()
		Program()
		Expect(_EOF)

	}

    func set (_ x: Int, _ y: Int) -> Bool { return Parser._set[x][y] }
    static let _set: [[Bool]] = [
		[_T,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x],
		[_x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_T, _T,_T,_T,_T, _T,_x,_x],
		[_x,_x,_x,_x, _x,_T,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_T,_x, _x,_x,_T,_T, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x],
		[_x,_x,_x,_T, _T,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _T,_T,_T,_T, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x],
		[_x,_T,_T,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _T,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _T,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x]

	]
} // end Parser


public class Errors {
    public var count = 0                                 // number of errors detected
    private let errorStream = Darwin.stderr              // error messages go to this stream
    public var errMsgFormat = "-- line %i col %i: %@"    // 0=line, 1=column, 2=text
    
    func Write(_ s: String) { fputs(s, errorStream) }
    func WriteLine(_ format: String, line: Int, col: Int, s: String) {
        let str = String(format: format, line, col, s)
        WriteLine(str)
    }
    func WriteLine(_ s: String) { Write(s + "\n") }
    
    public func SynErr (_ line: Int, col: Int, n: Int) {
        var s: String
        switch n {
		case 0: s = "EOF expected"
		case 1: s = "squared expected"
		case 2: s = "cubed expected"
		case 3: s = "times expected"
		case 4: s = "divide expected"
		case 5: s = "minus expected"
		case 6: s = "ident expected"
		case 7: s = "number expected"
		case 8: s = "octalInt expected"
		case 9: s = "hexInt expected"
		case 10: s = "binInt expected"
		case 11: s = "decInt expected"
		case 12: s = "baseInt expected"
		case 13: s = "\";\" expected"
		case 14: s = "\"let\" expected"
		case 15: s = "\"=\" expected"
		case 16: s = "\"(\" expected"
		case 17: s = "\")\" expected"
		case 18: s = "\"-\" expected"
		case 19: s = "\"~\" expected"
		case 20: s = "\"true\" expected"
		case 21: s = "\"false\" expected"
		case 22: s = "\"+\" expected"
		case 23: s = "\"|\" expected"
		case 24: s = "\"*\" expected"
		case 25: s = "\"/\" expected"
		case 26: s = "\"%\" expected"
		case 27: s = "\"&\" expected"
		case 28: s = "\"!\" expected"
		case 29: s = "\"^\" expected"
		case 30: s = "\"**\" expected"
		case 31: s = "\"==\" expected"
		case 32: s = "\"!=\" expected"
		case 33: s = "\"<=\" expected"
		case 34: s = "\"<\" expected"
		case 35: s = "\">\" expected"
		case 36: s = "\">=\" expected"
		case 37: s = "??? expected"
		case 38: s = "invalid RelOp"
		case 39: s = "invalid AddOp"
		case 40: s = "invalid MulOp"
		case 41: s = "invalid Factor"
		case 42: s = "invalid PowerOp"
		case 43: s = "invalid UnaryOp"

        default: s = "error \(n)"
        }
        WriteLine(errMsgFormat, line: line, col: col, s: s)
        count += 1
	}

    public func SemErr (_ line: Int, col: Int, s: String) {
        WriteLine(errMsgFormat, line: line, col: col, s: s);
        count += 1
    }
    
    public func SemErr (_ s: String) {
        WriteLine(s)
        count += 1
    }
    
    public func Warning (_ line: Int, col: Int, s: String) {
        WriteLine(errMsgFormat, line: line, col: col, s: s)
    }
    
    public func Warning(_ s: String) {
        WriteLine(s)
    }
} // Errors

