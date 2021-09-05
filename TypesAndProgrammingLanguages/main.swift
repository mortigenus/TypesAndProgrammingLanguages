//
//  main.swift
//  TypesAndProgrammingLanguages
//
//  Created by Ivan Chalov on 15.10.2020.
//

import Foundation

let chapters: [Runnable] = [
  Chapter04(),
  Chapter07(),
  Chapter10(),
]

func run(_ chapter: Runnable) {
  run([chapter])
}

func run(_ chapters: [Runnable] = chapters) {
  chapters.forEach { $0.main(); print("✅ \($0)") }
}

run(
//  Chapter10()
)
