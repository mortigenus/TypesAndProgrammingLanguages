//
//  Chapter07.swift
//  TypesAndProgrammingLanguages
//
//  Created by Ivan Chalov on 15.10.2020.
//

import Foundation

private enum Binding {
  case name
}

private struct VariableName: RawRepresentable, CustomStringConvertible, ExpressibleByStringLiteral, Equatable {
  typealias StringLiteralType = String

  var rawValue: String
  var description: String { rawValue }

  init(rawValue: String) {
    self.rawValue = rawValue
  }

  init(stringLiteral value: String) {
    self.rawValue = value
  }
}

private struct DeBruijnIndex: RawRepresentable, ExpressibleByIntegerLiteral, Equatable {
  typealias IntegerLiteralType = Int
  var rawValue: Int

  init(rawValue: Int) {
    self.rawValue = rawValue
  }

  init(integerLiteral value: Int) {
    self.rawValue = value
  }

  func shifted(by offset: Int) -> DeBruijnIndex {
    DeBruijnIndex(rawValue: rawValue + offset)
  }
}

private typealias Context = Array<(variable: VariableName, binding: Binding)>

private enum Command {
  case eval(Term)
  case bind(VariableName, Term)
}

private indirect enum Term: Equatable, Evaluatable {
  case variable(DeBruijnIndex, contextLength: Int)
  case abstraction(VariableName, Term)
  case application(Term, Term)
}

private extension VariableName {
  func slightlyModified() -> VariableName {
    VariableName(rawValue: self.rawValue + "'")
  }

  func isBound(in context: Context) -> Bool {
    context.contains { $0.variable == self }
  }

  func pickName(in context: Context) -> (Context, VariableName) {
    self.isBound(in: context)
      ? self.slightlyModified().pickName(in: context)
      : (context.adding(self), self)
  }
}

private extension Context {
  static func empty() -> Context {
    []
  }

  func adding(_ name: VariableName) -> Self {
    [(name,Binding.name)] + self
  }

  func name(from index: DeBruijnIndex) -> VariableName {
    self[index.rawValue].variable
  }
}

private extension Term {
  func map(transformVar: (DeBruijnIndex, Int, Int) -> Term) -> Term {
    func walk(cutoff: Int, term: Term) -> Self {
      switch term {
      case let .variable(x, contextLength: n):
        return transformVar(x, n, cutoff)
      case let .abstraction(x, t1):
        return .abstraction(x, walk(cutoff: cutoff + 1, term: t1))
      case let .application(t1, t2):
        return .application(walk(cutoff: cutoff, term: t1), walk(cutoff: cutoff, term: t2))
      }
    }
    return walk(cutoff: 0, term: self)
  }
}

private extension Term {
  func description(in context: Context) -> String {
    switch self {
    case let .abstraction(x, t1):
      let (ctx1, x1) = x.pickName(in: context)
      return "(lambda \(x1). \(t1.description(in: ctx1)))"
    case let .application(t1, t2):
      return "(\(t1.description(in: context)) \(t2.description(in: context)))"
    case let .variable(x, contextLength: n):
      if context.count == n {
        return String(describing: context.name(from: x))
      } else {
        return "[bad index]"
      }
    }
  }

  func shifted(by d: Int) -> Self {
    map { x, n, c in
      x.rawValue >= c
        ? .variable(x.shifted(by: d), contextLength: n + d)
        : .variable(x, contextLength: n + d)
    }
  }

  func substituted(at index: DeBruijnIndex, with term: Term) -> Self {
    map { x, n, c in
      x == index.shifted(by: c)
        ? term.shifted(by: c)
        : .variable(x, contextLength: n)
    }
  }

  func eval1() throws -> Term {
    self
  }

  func evalN() -> Term {
    self
  }
}

// Specialized assert to omit writing `Term.` every time.
private func assert(_ term: Term, evaluatesTo: Term, file: StaticString = #file, line: UInt = #line) {
  assert(value: term, evaluatesTo: evaluatesTo, file: file, line: line)
}

struct Chapter07: Runnable {
  func main() {
    print(Term
            .abstraction(
              "x",
              .application(
                .variable(0, contextLength: 3),
                .variable(1, contextLength: 3)))
            .description(in: Context.empty().adding("x").adding("x'")))
  }
}

