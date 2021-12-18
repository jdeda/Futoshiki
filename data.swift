//
//  data.swift
//  Futoshiki
//
//  Created by Jesse Deda on 12/13/21.
//

import Foundation
import OrderedCollections

enum ProgramError: Error {
  case readError(String)
  case argError(String)
  case fileError(String)
  case runtimeError(String)
}

func mapIdx(_ idxStr: String, _ n: Int) -> [Index] {
  let idxPar = idxStr.split(separator: " ")
  let idxInt = idxPar.compactMap { Int(String($0)) }
  let idxFin = idxInt.compactMap { Index(x: $0 / n, y: $0 % n) }
  return idxFin
}

func getBoard(_ fileFullPath: String) throws -> [[Variable]] {
  
  // Parse board file into lines.
  let path = URL.init(fileURLWithPath: fileFullPath)
  let text = try String(contentsOf: path, encoding: String.Encoding.utf8)
  var lines = text.components(separatedBy: "\n")
  lines = lines.compactMap { $0.replacingOccurrences(of: "\r", with: "")} // Extra.
  
  // Retrieve size of board.
  guard let N = Int(lines[0]) else {
    throw ProgramError.fileError("invalid file format")
  }
  
  // Initialize board.
  var board = [[Variable]]()
  for i in 0..<N {
    board.append([Variable]())
    for j in 0..<N {
      board[i].append(Variable(
        value: -1,
        domain: OrderedSet(1...N),
        constraints: Dictionary<Index, Bool>(),
        index: Index(x: i, y: j),
        predetermined: false)
      )
    }
  }
  
  // Set board with predetermined values.
  let idx_V = mapIdx(lines[1], N)
  let values = (lines[2].split(separator: " ")).compactMap { Int(String($0)) }
  for (i, idx) in idx_V.enumerated() {
    board[idx.x][idx.y] = Variable(
      value: values[i],
      domain: OrderedSet(arrayLiteral: values[i]),
      constraints: Dictionary<Index, Bool>(),
      index: Index(x: idx.x, y: idx.y),
      predetermined: true
    )
  }
  
  // Set board with predetermined constraints.
  
  // Get index pairs.
  let idx_A = mapIdx(lines[3], N)
  let idx_B = mapIdx(lines[4], N)
  let idx_Z = zip(idx_A, idx_B)
  
  // Make constraints for each variable.
  let idx_S = Set(idx_A + idx_B)
  var constraints_dictionary = Dictionary<Index, Dictionary<Index, Bool>>()
  for idx in idx_S {
    constraints_dictionary[idx] = Dictionary<Index, Bool>()
  }
  for (a, b) in idx_Z {
    constraints_dictionary[a]![b] = false
    constraints_dictionary[b]![a] = true
  }
  
  // Set constraints (except for predetermined variables).
  let idx_SS = Set(idx_V)
  for idx in idx_S {
    if !idx_SS.contains(idx) {
      board[idx.x][idx.y] = Variable(
        value: -1,
        domain: OrderedSet(1...N),
        constraints: constraints_dictionary[idx]!,
        index: idx, predetermined: false
      )
    }
  }
  
  // Return board.
  return board
}
