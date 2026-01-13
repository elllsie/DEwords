//
//  CrownStepper.swift
//  testCalc
//
//  Created by 彭滢 on 2026/1/13.
//

import SwiftUI
import WatchKit

/// 一个表冠离散步进组件
/// 每转满阈值就触发一次动作
struct CrownStepper: ViewModifier {

    /// 阈值：表冠累计到多少触发一次动作
    let threshold: Double
    let onStepForward: () -> Void
    let onStepBackward: () -> Void

    @Binding var crownValue: Double
    @State private var accumulated: Double = 0

    func body(content: Content) -> some View {
        content
            .digitalCrownRotation(
                $crownValue,
                from: -1000,
                through: 1000,
                by: 1 // 保持精细
            )
            .onChange(of: crownValue) { oldValue, newValue in
                let delta = newValue - oldValue
                accumulated += delta

                if accumulated >= threshold {
                    onStepForward()
                    accumulated = 0
                    WKInterfaceDevice.current().play(.click)
                } else if accumulated <= -threshold {
                    onStepBackward()
                    accumulated = 0
                    WKInterfaceDevice.current().play(.click)
                }
            }
    }
}

extension View {
    /// 方便调用
    func crownStepper(
        crownValue: Binding<Double>,
        threshold: Double = 6,
        onStepForward: @escaping () -> Void,
        onStepBackward: @escaping () -> Void
    ) -> some View {
        self.modifier(
            CrownStepper(
                threshold: threshold,
                onStepForward: onStepForward,
                onStepBackward: onStepBackward,
                crownValue: crownValue
            )
        )
    }
}
