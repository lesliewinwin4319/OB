//
//  OBApp.swift
//  OB
//
//  Created by leslie on 2026/4/4.
//

import SwiftUI

@main
struct OBApp: App {
    @StateObject private var toastManager = ToastManager.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()

                // 全局 Toast 覆盖层
                ToastView(toastManager: toastManager)
                    .ignoresSafeArea()
            }
        }
    }
}
