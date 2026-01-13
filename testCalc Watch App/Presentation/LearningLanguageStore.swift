//
//  LearningLanguageStore.swift
//  testCalc
//
//  Created by 彭滢 on 2026/1/10.
//
import SwiftUI

enum LearningLanguage: String {
    case zh
    case en
}

struct LearningLanguageStore {

    private static let key = "learningLanguage"

    static func get() -> LearningLanguage? {
        guard let raw = UserDefaults.standard.string(forKey: key) else {
            return nil
        }
        return LearningLanguage(rawValue: raw)
    }

    static func set(_ lang: LearningLanguage) {
        UserDefaults.standard.set(lang.rawValue, forKey: key)
    }
}
