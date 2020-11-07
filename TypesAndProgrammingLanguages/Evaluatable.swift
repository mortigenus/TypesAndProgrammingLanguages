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
  associatedtype Context
  func eval1(in context: Context) throws -> Self
  func evalN(in context: Context) -> Self
  func eval(with strategy: Strategy, in context: Context) -> Self
}

extension Evaluatable {
  func eval(with strategy: Strategy = .evalN, in context: Context) -> Self {
    switch strategy {
    case .eval1:
      do {
        return try self.eval1(in: context).eval(with: strategy, in: context)
      } catch {
        return self
      }
    case .evalN:
      return self.evalN(in: context)
    }
  }
}

func assert<T: Evaluatable & Equatable>(
  value: T,
  evaluatesTo: T,
  in context: T.Context,
  file: StaticString = #file,
  line: UInt = #line
) {
  Strategy.allCases.forEach {
    Swift.assert(
      value.eval(with: $0, in: context) == evaluatesTo,
      "Evaluation failed for strategy \($0)",
      file: file,
      line: line)
  }
}
