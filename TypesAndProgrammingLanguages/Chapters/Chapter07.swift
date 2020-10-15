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

private typealias Context = Array<(String, Binding)>
private extension Context {
  static func empty() -> Context {
    []
  }

  func isBound(name: String) -> Bool {
    self.contains { x, _  in x == name }
  }

  func adding(name: String) -> Self {
    [(name,Binding.name)] + self
  }

  func pickFreshName(for x: String) -> (Context, String) {
    isBound(name: x)
      ? pickFreshName(for: x + "'")
      : (adding(name: x), x)
  }

  func name(from index: Int) -> String {
    self[index].0
  }
}

private enum Command {
  case eval(Term)
  case bind(name: String, Term)
}

private indirect enum Term {
  case variable(index: Int, contextLength: Int)
  case abstraction(name: String, Term)
  case application(Term, Term)

  func print(in context: Context) -> String {
    switch self {
    case let .abstraction(name: x, t1):
      let (ctx1, x1) = context.pickFreshName(for: x)
      return "(lambda \(x1). \(t1.print(in: ctx1)))"
    case let .application(t1, t2):
      return "(\(t1.print(in: context)) \(t2.print(in: context)))"
    case let .variable(index: i, contextLength: n):
      if context.count == n {
        return context.name(from: i)
      } else {
        return "[bad index]"
      }
    }
  }
}

struct Chapter07: Runnable {
  func main() {
    print(Term
            .abstraction(
              name: "x",
              .application(
                .variable(index: 0, contextLength: 3),
                .variable(index: 1, contextLength: 3)))
            .print(in: Context.empty().adding(name: "x").adding(name: "x'")))
  }
}

