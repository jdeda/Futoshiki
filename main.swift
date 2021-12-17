//
//  main.swift
//  Futoshiki
//
//  Created by Jesse Deda on 12/11/21.
//

import Foundation


// Collect and build data for CSP.
let args = CommandLine.arguments
if args.count != 4 { throw ProgramError.argError("must input exactly 3 commands") }
guard let filter = Filter(rawValue: args[1]) else { throw ProgramError.argError("invalid filter") }
guard let order = Order(rawValue: args[2]) else { throw ProgramError.argError("invalid order") }
let board = try getBoard(args[3])
let assignment = Assignment(board: board, failure: false)
let csp = CSP()

// Solve CSP.
let final = backtrack(assignment: assignment, csp: csp, filter: filter)

// Print CSP.
if final.failure {
  print("WTF")
}
final.board.forEach {
    $0.forEach {
        print($0.value, separator: " ", terminator: " ")
    }
    print("\n")
}
print("\n")
final.board.forEach {
    $0.forEach {
        print($0.domain.count, separator: " ", terminator: " ")
    }
    print("\n")
}
