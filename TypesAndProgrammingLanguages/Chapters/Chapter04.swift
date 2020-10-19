//
//  Chapter04.swift
//  TypesAndProgrammingLanguages
//
//  Created by Ivan Chalov on 15.10.2020.
//

import Foundation


private indirect enum Term: Equatable, Evaluatable {
  case `true`
  case `false`
  case `if`(Term, Term, Term)
  case zero
  case succ(Term)
  case pred(Term)
  case isZero(Term)

  func isNumericValue() -> Bool {
    switch self {
    case .zero:
      return true
    case let .succ(term):
      return term.isNumericValue()
    default:
      return false
    }
  }

  func isValue() -> Bool {
    switch self {
    case .true, .false:
      return true
    default:
      return self.isNumericValue()
    }
  }

  func eval1() throws -> Term {
    switch self {
    case let .if(.true, t2, _):
      return t2
    case let .if(.false, _, t3):
      return t3
    case let .if(t1, t2, t3):
      return .if(try t1.eval1(), t2, t3)
    case let .succ(t1):
      return .succ(try t1.eval1())
    case .pred(.zero):
      return .zero
    case let .pred(.succ(nv1)) where nv1.isNumericValue():
      return nv1
    case let .pred(t1):
      return .pred(try t1.eval1())
    case .isZero(.zero):
      return .true
    case let .isZero(.succ(nv1)) where nv1.isNumericValue():
      return .false
    case let .isZero(t1):
      return .isZero(try t1.eval1())
    default:
      throw NoRuleApplies()
    }
  }

  func evalN() -> Term {
    switch self {
    case .true, .false, .zero:
      return self
    case let .if(t1, t2, t3):
      let evaled = t1.evalN()
      if evaled == .true {
        return t2.evalN()
      } else if evaled == .false {
        return t3.evalN()
      } else {
        return self
      }
    case let .succ(t1):
      let evaled = t1.evalN()
      if evaled.isNumericValue() {
        return .succ(evaled)
      } else {
        return self
      }
    case let .pred(t1):
      let evaled = t1.evalN()
      if evaled == .zero {
        return .zero
      } else if case let .succ(nv1) = evaled, nv1.isNumericValue() {
        return nv1
      } else {
        return .pred(evaled)
      }
    case let .isZero(t1):
      let evaled = t1.evalN()
      if evaled == .zero {
        return .true
      } else if case .succ(_) = evaled {
        return .false
      } else {
        return self
      }
    }
  }
}

// Specialized assert to omit writing `Term.` every time.
private func assert(_ term: Term, evaluatesTo: Term, file: StaticString = #file, line: UInt = #line) {
  assert(value: term, evaluatesTo: evaluatesTo, file: file, line: line)
}

struct Chapter04: Runnable {
  func main() {
    // 1. Value -> Value
    assert(.true, evaluatesTo: .true)
    assert(.false, evaluatesTo: .false)
    assert(.zero, evaluatesTo: .zero)

    // 2. t1 -> true, t2 -> v2 => if t1 then t2 else t3 -> v2
    assert(
      .if(.true, .zero, .succ(.zero)),
      evaluatesTo: .zero)
    assert(
      .if(.isZero(.pred(.succ(.zero))), .succ(.succ(.zero)), .succ(.zero)),
      evaluatesTo: .succ(.succ(.zero)))

    // 3. t1 -> false, t3 -> v3 => if t1 then t2 else t3 -> v3
    assert(
      .if(.false, .succ(.zero), .zero),
      evaluatesTo: .zero)
    assert(
      .if(.isZero(.succ(.succ(.zero))), .pred(.zero), .succ(.pred(.zero))),
      evaluatesTo: .succ(.zero))

    // 4. t1 -> nv1 => succ t1 -> succ nv1
    assert(.succ(.zero), evaluatesTo: .succ(.zero))
    assert(.succ(.succ(.succ(.zero))), evaluatesTo: .succ(.succ(.succ(.zero))))

    // 5. t1 -> 0 => pred t1 -> 0
    assert(.pred(.zero), evaluatesTo: .zero)
    assert(.pred(.pred(.pred(.zero))), evaluatesTo: .zero)
    assert(.pred(.pred(.succ(.pred(.succ(.zero))))), evaluatesTo: .zero)

    // 6. t1 -> succ nv1 => pred t1 -> nv1
    assert(.pred(.succ(.zero)), evaluatesTo: .zero)
    assert(.pred(.succ(.succ(.pred(.succ(.zero))))), evaluatesTo: .succ(.zero))

    // 7. t1 -> 0 => isZero t1 -> true
    assert(.isZero(.zero), evaluatesTo: .true)
    assert(.isZero(.pred(.zero)), evaluatesTo: .true)
    assert(.isZero(.pred(.succ(.pred(.pred(.zero))))), evaluatesTo: .true)

    // 8. t1 -> succ nv1 => isZero t1 -> false
    assert(.isZero(.succ(.zero)), evaluatesTo: .false)
    assert(.isZero(.succ(.succ(.zero))), evaluatesTo: .false)
    assert(.isZero(.succ(.pred(.succ(.pred(.pred(.zero)))))), evaluatesTo: .false)

    print("✅ Chapter04")
  }
}

