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


struct Index: Hashable { // baggage. fixed sized array? tuples are not hashable.
    let x: Int
    let y: Int
}

// MUTATES.
struct Variable {
    var value: Int
    var domain: OrderedSet<Int>
    let constraints: Dictionary<Index, Bool> // messy.
    let index: Index
    let predetermined: Bool // oobject should really be immutable...
}

// MUTATES.
class Assignment {
    var board: [[Variable]]
    var failure: Bool
    var unassignedIdx: Index // baggage.
    var unassigned: Variable {
        return self.board[self.unassignedIdx.x][self.unassignedIdx.y]
    }
    let defaultAssignment = -1

    init (board: [[Variable]], failure: Bool) {
        self.board = board
        self.failure = failure
        self.unassignedIdx = Index(x: 0, y:0)
    }

    convenience init(failure: Bool) {
        self.init(board: [[Variable]](), failure: true)
    }
    
    func moveIndexForward() {
        repeat {
            if self.unassignedIdx.y + 1 == self.board.count {
                if self.unassignedIdx.x == self.board.count - 1 { // Hacky.
                    self.unassignedIdx = Index(x: self.board.count - 1, y: self.board.count - 1)
                    return
                }
                self.unassignedIdx = Index(x: self.unassignedIdx.x + 1, y: 0)
            }
            else {
                self.unassignedIdx = Index(x: self.unassignedIdx.x, y: unassignedIdx.y + 1)
            }
        } while (self.board[self.unassignedIdx.x][self.unassignedIdx.y].predetermined)
    }
    
    func moveIndexBackward() {
        repeat {
            if self.unassignedIdx.y - 1 == -1 {
                if self.unassignedIdx.x == 0 { // Hacky.
                    self.unassignedIdx = Index(x: 0, y: 0)
                    return
                }
                self.unassignedIdx = Index(x: self.unassignedIdx.x - 1, y: self.board.count - 1)
            }
            else {
                self.unassignedIdx = Index(x: self.unassignedIdx.x, y: unassignedIdx.y - 1)
            }
        } while (self.board[self.unassignedIdx.x][self.unassignedIdx.y].predetermined)
        
    }
    
    // DONE.
    func assign(_ variable: Variable, _ value: Int) {
        self.board[variable.index.x][variable.index.y].value = value
        moveIndexForward()
    }
    
    // DONE.
    func unassign(_ variable: Variable) {
        self.board[variable.index.x][variable.index.y].value = self.defaultAssignment
        moveIndexBackward()
        
    }
    
    // DONE.
    // Ugly. Sets require hashable, gross.
    func neighbors(of: Variable, except: Variable) -> [Variable] {
        let neighsDirty = self.board[of.index.x] + self.board[of.index.y]
        var neighsClean = neighsDirty
        for (idx, n) in neighsDirty.enumerated() {
            if n.index == of.index || n.index == except.index {
                neighsClean.remove(at: idx)
            }
        }
        return neighsClean
    }
}

// DONE.
enum Filter: String {
    case MAC = "MAC"
}

// DONE.
enum Order: String {
    case normal = "normal"
}

struct CSP {
    
    // DONE.
    func isComplete(_ assignment: Assignment) -> Bool {
        let c = assignment.board.count - 1
        let last = assignment.board[c][c]
        if assignment.unassignedIdx.x == c && assignment.unassignedIdx.y == c && assignment.unassigned.value != -1 {
            return isConsistent(last.value, last, assignment)
        }
        return false
    }
    
    // DONE.
    func isConsistent(_ value: Int, _ variable: Variable, _ assignment: Assignment) -> Bool {
        
        // Copy variable and update its value for testing.
        var test = variable
        test.value = value
    
        // Check for valid AB pairs and or duplicates in corresponding row.
        let row = assignment.board[test.index.x]
        for rowVar in row {
            if rowVar.index.x == test.index.x && rowVar.index.y == test.index.y {
                continue
            }
            if test.value == rowVar.value {
                return false
            }
            if isAdjacent(rowVar.index.y, test.index.y, assignment.board.count) && rowVar.value != -1 && !isConsistentAB(rowVar, test) {
                    return false
            }
        }
        
        // Check for valid AB pairs and or duplicates in corresponding col.
        let col = assignment.board[0..<assignment.board.count].map { $0[test.index.y] }
        for colVar in col {
            if colVar.index.x == test.index.x && colVar.index.y == test.index.y {
                continue
            }
            if test.value == colVar.value {
                return false
            }
            if isAdjacent(colVar.index.x, test.index.x, assignment.board.count) && colVar.value != -1 && !isConsistentAB(colVar, test) {
                    return false
            }
        }
        
        // Passed all tests.
        return true
    }
    
    // DONE.
    func isAdjacent(_ idx1: Int, _ idx2: Int, _ n: Int) -> Bool {
        return (idx1 == idx2 + 1 && idx2 + 1 < n) || (idx1 == idx2 - 1 && idx2 - 1 >= 0)
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
        if var1LessThan == true && var2LessThan == false {
            return var1.value < var2.value
        }
        else if var1LessThan == false && var2LessThan == true {
            return var1.value > var2.value
        }
        else {
            return false
        }
    }
    
    // DONE.
    func inference(_ assignment: Assignment, _ filter: Filter) -> Bool {
        switch filter {
            case .MAC: return self.inferMAC(assignment)
        }
    }
    
    // DONE.
    func revise(_ Xi: inout Variable, _ Xj: Variable) -> Bool {
        var revised = false
        for x in Xi.domain {
            var noVal = true
            for y in Xj.domain{
                if x != y {
                    noVal = false
                }
            }
            if noVal {
                Xi.domain.remove(x)
                revised = true
            }
        }
        return revised
    }
    
    func inferMAC(_ assignment: Assignment) -> Bool {
        
        // Make queue.
        var queue = Deque<(Variable, Variable)>()
        while !queue.isEmpty {
            var (Xi, Xj) = queue.popLast()!
            if !Xi.predetermined {
                if revise(&Xi, Xj) {
                    if Xi.domain.isEmpty {
                        return false
                    }
                    for Xk in assignment.neighbors(of: Xi, except: Xj) {
                        queue.append((Xk, Xi))
                    }
                }
            }
        }
        return true
    }
}

func backtrack(assignment: Assignment, csp: CSP, filter: Filter) -> Assignment {
    if csp.isComplete(assignment) { return assignment }
    let variable = assignment.unassigned
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
