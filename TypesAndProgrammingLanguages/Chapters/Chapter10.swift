//
//  Chapter10.swift
//  TypesAndProgrammingLanguages
//
//  Created by Ivan Chalov on 05.09.2021.
//

import Foundation

private indirect enum Type: Equatable {
  case arrow(from: Type, to: Type)
  case bool
}

private enum Binding {
  case name
  case variable(of: Type)
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
}

private indirect enum Term: Equatable {
  typealias Context = Array<(variable: VariableName, binding: Binding)>

  case variable(DeBruijnIndex, contextLength: Int)
  case abstraction(VariableName, Type, Term)
  case application(Term, Term)
  case `true`
  case `false`
  case `if`(Term, Term, Term)
}

private extension Term.Context {
  static func empty() -> Self {
    []
  }

  func adding(name: VariableName, binding: Binding) -> Self {
    [(name, binding)] + self
  }

  func binding(at index: DeBruijnIndex) -> Binding {
    self[index.rawValue].binding
  }

  func type(at index: DeBruijnIndex) -> Type? {
    guard case let .variable(of: type) = binding(at: index) else {
      return nil
    }
    return type
  }
}

private enum TypeError: Error {
  case typeNotFound
  case parameterMismatch
  case unexpectedType
  case conditionalArmsTypeMismatch
  case guardNotBool
}

extension Term {
  func type(in context: Context) throws -> Type {
    switch self {
    case let .variable(index, contextLength: _):
      guard let type = context.type(at: index) else {
        throw TypeError.typeNotFound
      }
      return type
    case let .abstraction(name, term1Type, term2):
      let term2Type = try term2.type(
        in: context.adding(
          name: name,
          binding: .variable(of: term1Type)))
      return .arrow(from: term1Type, to: term2Type)
    case let .application(term1, term2):
      let term1Type = try term1.type(in: context)
      let term2Type = try term2.type(in: context)
      switch term1Type {
      case let .arrow(from: term1FromType, to: term1ToType) where term1FromType == term2Type:
        return term1ToType
      case .arrow:
        throw TypeError.parameterMismatch
      default:
        throw TypeError.unexpectedType
      }
    case .true, .false:
      return .bool
    case let .if(term1, term2, term3):
      guard try term1.type(in: context) == .bool else {
        throw TypeError.guardNotBool
      }
      let term2Type = try term2.type(in: context)
      let term3Type = try term3.type(in: context)
      guard term2Type == term3Type else {
        throw TypeError.conditionalArmsTypeMismatch
      }
      return term2Type
    }
  }
}

// Specialized assert to omit writing `Term.` every time.
private func assert(_ term: Term, is type: Type, file: StaticString = #file, line: UInt = #line) {
  let termType = try! term.type(in: .empty())
  Swift.assert(termType == type, file: file, line: line)
}

private func assertTypingFails(for term: Term, with typeError: TypeError, in context: Term.Context? = nil, file: StaticString = #file, line: UInt = #line) {
  do {
    _ = try term.type(in: context ?? .empty())
    assert(false, file: file, line: line)
  } catch {
    assert((error as? TypeError) == typeError, file: file, line: line)
  }
}

struct Chapter10: Runnable {
  func main() {
    assert(.true, is: .bool)
    assert(.false, is: .bool)
    assert(.if(.true, .false, .true), is: .bool)

    assert(
      .abstraction("x", .bool, .variable(0, contextLength: 1)),
      is: .arrow(from: .bool, to: .bool))

    assert(
      .application(
        .if(
          .false,
          .abstraction("x", .bool, .variable(0, contextLength: 1)),
          .abstraction("y", .bool, .variable(0, contextLength: 1))),
        .true
      ),
      is: .bool)

    assert(
      .application(
        .if(
          .application(
            .if(
              .true,
              .abstraction("x", .bool, .variable(0, contextLength: 1)),
              .abstraction("y", .bool, .variable(0, contextLength: 1))),
            .false
          ),
          .abstraction("x", .bool, .variable(0, contextLength: 1)),
          .abstraction("y", .bool, .variable(0, contextLength: 1))),
        .true
      ),
      is: .bool)

    assertTypingFails(
      for: .variable(0, contextLength: 1),
      with: .typeNotFound,
      in: Term.Context([("x", .name)]))

    assertTypingFails(
      for: .application(
        .abstraction(
          "x",
          .arrow(from: .bool, to: .bool),
          .variable(0, contextLength: 1)),
        .true),
      with: .parameterMismatch)

    assertTypingFails(
      for: .application(
        .true,
        .abstraction("x", .bool, .variable(0, contextLength: 1))),
      with: .unexpectedType)

    assertTypingFails(
      for: .if(
        .true,
        .abstraction("x", .bool, .variable(0, contextLength: 1)),
        .false),
      with: .conditionalArmsTypeMismatch)

    assertTypingFails(
      for: .if(
        .abstraction("x", .bool, .variable(0, contextLength: 1)),
        .true,
        .false),
      with: .guardNotBool)
  }
}
