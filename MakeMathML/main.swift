//
//  main.swift
//  MakeMathML
//
//  Created by Mike Griebling on 13 Aug 2017.
//  Copyright © 2017 Computer Inspirations. All rights reserved.
//

import Foundation

let inputs = CommandLine.arguments
/* check on correct parameter usage */
if inputs.count < 2 {
    print("No input file specified")
} else {
    /* open the source file (Scanner.S_src)  */
    let srcName = inputs[1]
    let input = InputStream(fileAtPath: srcName)!
    let scanner = Scanner(s: input)
    
    print("Parsing")
    let parser = Parser(scanner: scanner)
    parser.Parse()
    
    if parser.errors.count > 0 {
        print("Compilation with Errors")
    } else {
        print("Parsed correctly")
    }
}


