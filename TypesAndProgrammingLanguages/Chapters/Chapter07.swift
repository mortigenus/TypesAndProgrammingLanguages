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

private enum Command {
  case eval(Term)
  case bind(VariableName, Term)
}

private indirect enum Term: Equatable, Evaluatable {
  typealias Context = Array<(variable: VariableName, binding: Binding)>

  case variable(DeBruijnIndex, contextLength: Int)
  case abstraction(VariableName, Term)
  case application(Term, Term)
}

private extension VariableName {
  func slightlyModified() -> VariableName {
    VariableName(rawValue: self.rawValue + "'")
  }

  func isBound(in context: Term.Context) -> Bool {
    context.contains { $0.variable == self }
  }

  func pickName(in context: Term.Context) -> (Term.Context, VariableName) {
    self.isBound(in: context)
      ? self.slightlyModified().pickName(in: context)
      : (context.adding(self), self)
  }
}

private extension Term.Context {
  static func empty() -> Self {
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

  func substitutedTop(with term: Term) -> Term {
    self.substituted(at: 0, with: term.shifted(by: 1)).shifted(by: -1)
  }

  func isValue(in context: Context) -> Bool {
    if case .abstraction = self {
      return true
    } else {
      return false
    }
  }

  func eval1(in context: Context) throws -> Term {
    switch self {
    case let .application(.abstraction(_, t12), v2) where v2.isValue(in: context):
      return t12.substitutedTop(with: v2)
    case let .application(v1, t2) where v1.isValue(in: context):
      return .application(v1, try t2.eval1(in: context))
    case let .application(t1, t2):
      return .application(try t1.eval1(in: context), t2)
    default:
      throw NoRuleApplies()
    }
  }

  func evalN(in context: Context) -> Term {
    guard case let .application(t1, t2) = self else {
      return self
    }
    let t1evaled = t1.evalN(in: context)
    let t2evaled = t2.evalN(in: context)
    if case let .abstraction(_, t12) = t1evaled, t2evaled.isValue(in: context) {
      return t12.substitutedTop(with: t2evaled).evalN(in: context)
    } else {
      return self
    }
  }
}

// Specialized assert to omit writing `Term.` every time.
private func assert(_ term: Term, evaluatesTo: Term, file: StaticString = #file, line: UInt = #line) {
  assert(value: term, evaluatesTo: evaluatesTo, in: .empty(), file: file, line: line)
}

struct Chapter07: Runnable {
  func main() {
    assert(
      .variable(0, contextLength: 1),
      evaluatesTo: .variable(0, contextLength: 1)
    )

    assert(
      .abstraction("x", .variable(0, contextLength: 1)),
      evaluatesTo: .abstraction("x", .variable(0, contextLength: 1))
    )

    assert(
      .application(
        .variable(0, contextLength: 2),
        .variable(1, contextLength: 2)),
      evaluatesTo: .application(
        .variable(0, contextLength: 2),
        .variable(1, contextLength: 2)))

    assert(
      .application(
        .abstraction("x1", .variable(0, contextLength: 2)),
        .abstraction("x2", .variable(1, contextLength: 2))),
      evaluatesTo: .abstraction("x2", .variable(1, contextLength: 2)))

    assert(
      .application(
        .application(
          .abstraction("x", .variable(0, contextLength: 1)),
          .abstraction(
            "x",
            .application(
              .variable(0, contextLength: 1),
              .variable(0, contextLength: 1)))),
        .abstraction(
          "y",
          Term.application(
            .abstraction("x", .variable(0, contextLength: 2)),
            .abstraction("x", .variable(0, contextLength: 2))))),
      evaluatesTo: .abstraction("x", .variable(0, contextLength: 1)))
  }
}

