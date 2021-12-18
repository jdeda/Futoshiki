//
//  futoshiki.swift
//  Futoshiki
//
//  Created by Jesse Deda on 11/20/21.
//
//  Futoshiki solver.

import Foundation
import DequeModule
import OrderedCollections

struct Pair: Hashable {
  let Xi: Variable
  let Xj: Variable
}

struct Index: Hashable {
  let x: Int
  let y: Int
}

struct Variable: Hashable {
  var value: Int
  var domain: OrderedSet<Int>
  let constraints: Dictionary<Index, Bool>
  let index: Index
  let predetermined: Bool // object should really be immutable...
}

class Assignment {
  let dim: Int
  var board: [[Variable]]
  var firstUnassignedIndex: Index
  var firstUnassigned: Variable {
    return self.board[self.firstUnassignedIndex.x][self.firstUnassignedIndex.y]
  }
  let unassignedValue = -1
  let failure: Bool
  
  init (board: [[Variable]], failure: Bool) {
    self.board = board
    self.failure = failure
    self.firstUnassignedIndex = Index(x: 0, y:0)
    self.dim = board.count
  }
  
  convenience init(failure: Bool) {
    self.init(board: [[Variable]](), failure: true)
  }
  
  func moveIndexForward() {
    repeat {
      if self.firstUnassignedIndex.y + 1 == self.dim {
        if self.firstUnassignedIndex.x == self.dim - 1 { // Hacky.
          self.firstUnassignedIndex = Index(x: self.dim - 1, y: self.dim - 1)
          return
        }
        self.firstUnassignedIndex = Index(x: self.firstUnassignedIndex.x + 1, y: 0)
      }
      else {
        self.firstUnassignedIndex = Index(x: self.firstUnassignedIndex.x, y: firstUnassignedIndex.y + 1)
      }
    } while (self.board[self.firstUnassignedIndex.x][self.firstUnassignedIndex.y].predetermined)
  }
  
  func moveIndexBackward() {
    repeat {
      if self.firstUnassignedIndex.y - 1 == -1 {
        if self.firstUnassignedIndex.x == 0 {
          self.firstUnassignedIndex = Index(x: 0, y: 0)
          return
        }
        self.firstUnassignedIndex = Index(x: self.firstUnassignedIndex.x - 1, y: self.dim - 1)
      }
      else {
        self.firstUnassignedIndex = Index(x: self.firstUnassignedIndex.x, y: firstUnassignedIndex.y - 1)
      }
    } while (self.board[self.firstUnassignedIndex.x][self.firstUnassignedIndex.y].predetermined)
    
  }
  
  func assign(_ variable: Variable, _ value: Int) {
    self.board[variable.index.x][variable.index.y].value = value
    moveIndexForward()
  }
  
  func unassign(_ variable: Variable) {
    self.board[variable.index.x][variable.index.y].value = self.unassignedValue
    moveIndexBackward()
    
  }
  
  func isUnassigned(_ variable: Variable) -> Bool {
    return variable.value == self.unassignedValue
  }
  
  func neighbors(of: Variable, except: Variable) -> [Variable] {
    let row = self.board[of.index.x]
    let col = self.board[0..<self.dim].map { $0[of.index.y] }
    var neighbors = Set(row + col)
    neighbors.remove(except)
    neighbors.remove(of)
    return Array(neighbors)
  }
  
  func neighbors(of: Variable) -> [Variable] {
    let row = self.board[of.index.x]
    let col = self.board[0..<self.dim].map { $0[of.index.y] }
    var neighbors = Set(row + col)
    neighbors.remove(of)
    return Array(neighbors)
  }
}

enum Filter: String {
  case MAC = "MAC"
  case NONE = "none"
}

enum Order: String {
  case normal = "normal"
  case minimal = "minimal"
}

struct CSP {
  
  func isComplete(_ assignment: Assignment) -> Bool {
    let last = assignment.board[assignment.dim - 1][assignment.dim - 1]
    if !assignment.isUnassigned(last) {
      return isConsistent(last.value, last, assignment)
    }
    return false
  }
  
  func isConsistent(_ value: Int, _ variable: Variable, _ assignment: Assignment) -> Bool {
    
    // Copy variable and update its value for testing.
    var test = variable
    test.value = value
    
    // Check for valid AB pairs and or duplicates in corresponding row.
    let row = assignment.board[test.index.x]
    for rowVar in row {
      if rowVar.index == test.index {
        continue
      }
      if test.value == rowVar.value {
        return false
      }
      if isAdjacent(rowVar, test, assignment.dim) && !assignment.isUnassigned(rowVar) && !isConsistentAB(rowVar, test) {
        return false
      }
    }
    
    // Check for valid AB pairs and or duplicates in corresponding col.
    let col = assignment.board[0..<assignment.dim].map { $0[test.index.y] }
    for colVar in col {
      if colVar.index == test.index {
        continue
      }
      if test.value == colVar.value {
        return false
      }
      if isAdjacent(colVar, test, assignment.dim) && !assignment.isUnassigned(colVar) && !isConsistentAB(colVar, test) {
        return false
      }
    }
    
    // Passed all tests.
    return true
  }
  
  // DONE.
  func isAdjacent(_ var1: Variable, _ var2: Variable, _ n: Int) -> Bool {
    if var1.index.x == var2.index.x {
      return isAdjacentIndex(var1.index.y, var2.index.y, n)
    }
    else if var1.index.y == var2.index.y {
      return isAdjacentIndex(var1.index.x, var2.index.x, n)
    }
    else {
      return false
    }
  }
  
  func isAdjacentIndex(_ i: Int, _ j: Int, _ n: Int) -> Bool {
    return (i == j + 1 && j + 1 < n) || (i == j - 1 && j - 1 >= 0)
  }
  
  // DONE.
  func isConsistentAB(_ var1: Variable, _ var2: Variable) -> Bool {
    
    // Make sure both variables contain eachother in constraints.
    guard let var1LessThan = var1.constraints[var2.index] else {
      return true
    }
    guard let var2LessThan = var2.constraints[var1.index] else {
      return true
    }
    
    // Test conditions.
    if var1LessThan && !var2LessThan {
      return var1.value < var2.value
    }
    else if !var1LessThan && var2LessThan {
      return var1.value > var2.value
    }
    else {
      return false
    }
  }
  
  func inference(_ assignment: Assignment, _ filter: Filter) -> Bool {
    switch filter {
    case .MAC: return self.inferMAC(assignment)
    case .NONE: return true
    }
  }
  
  func revise(_ Xi: inout Variable, _ Xj: Variable, _ assignment: Assignment) -> Bool {
    var revised = false
    for x in Xi.domain {
      var noVal = true
      for y in Xj.domain{
        if x != y { // TODO: If Xi Xj adjacent and AB pair...could be a problem.
          noVal = false
        }
      }
      if noVal {
        assignment.board[Xi.index.x][Xi.index.y].domain.remove(x)
        revised = true
      }
    }
    return revised
  }
  
  func inferMAC(_ assignment: Assignment) -> Bool {
    
    // Make queue.
    let variables = assignment.board.flatMap { $0 }
    let pairs = variables.map { xi in
      assignment.neighbors(of: xi).map { xj in
        Pair(Xi: xi, Xj: xj)
      }
    }.flatMap { $0 }
    var queue = Deque(Set(pairs))
    
    // Peform MAC.
    while !queue.isEmpty {
      let pair = queue.popFirst()!
      let Xj = pair.Xj
      var Xi = pair.Xi
      if Xi.predetermined {
        continue
      }
      if revise(&Xi, Xj, assignment) { // TODO: amper?
        if Xi.domain.isEmpty {
          return false
        }
        for Xk in assignment.neighbors(of: Xi, except: Xj) {
          queue.append(Pair(Xi: Xk, Xj: Xi))
        }
      }
    }
    return true
  }
}

func backtrack(assignment: Assignment, csp: CSP, filter: Filter) -> Assignment {
  if csp.isComplete(assignment) { return assignment }
  let variable = assignment.firstUnassigned
  for value in variable.domain {
    if csp.isConsistent(value, variable, assignment) {
      assignment.assign(variable, value)
      let inference = csp.inference(assignment, filter)
      if inference {
        let result = backtrack(assignment: assignment, csp: csp, filter: filter)
        if !result.failure { return result }
        else { assignment.unassign(variable) }
      }
    }
  }
  return Assignment(failure: true)
}
