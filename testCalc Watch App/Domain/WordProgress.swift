//
//  WordProgress.swift
//  testCalc
//
//  Created by 彭滢 on 2026/1/4.
//

import Foundation

struct WordProgress: Codable {
    var familiarCount: Int = 0
    // 下一次可出现的“时间轴步数”（不是数组索引）
    var nextAvailableStep: Int = 0

    // 兼容旧字段名：nextAvailableIndex
    enum CodingKeys: String, CodingKey {
        case familiarCount
        case nextAvailableStep = "nextAvailableIndex"
    }
}
