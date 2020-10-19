//
//  Evaluatable.swift
//  TypesAndProgrammingLanguages
//
//  Created by Ivan Chalov on 19.10.2020.
//

import Foundation


struct NoRuleApplies: Error {}
enum Strategy: CaseIterable {
  case eval1
  case evalN
}

protocol Evaluatable {
  func eval1() throws -> Self
  func evalN() -> Self
  func eval(strategy: Strategy) -> Self
}

extension Evaluatable {
  func eval(strategy: Strategy = .evalN) -> Self {
    switch strategy {
    case .eval1:
      do {
        return try self.eval1().eval(strategy: strategy)
      } catch {
        return self
      }
    case .evalN:
      return self.evalN()
    }
  }
}

func assert<T: Evaluatable & Equatable>(
  value: T,
  evaluatesTo: T,
  file: StaticString = #file,
  line: UInt = #line
) {
  Strategy.allCases.forEach {
    Swift.assert(
      value.eval(strategy: $0) == evaluatesTo,
      "Evaluation failed for strategy \($0)",
      file: file,
      line: line)
  }
}
