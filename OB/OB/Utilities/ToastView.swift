// ToastView.swift
// OB App - 全局 Toast 视图组件
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-07

import SwiftUI

// MARK: - ToastView

/// 全局 Toast 视图，覆盖在 App 最顶层
/// 样式与现有页面局部 Toast 保持一致：黑底白字胶囊
struct ToastView: View {

    @ObservedObject var toastManager: ToastManager

    var body: some View {
        if let toast = toastManager.currentToast {
            VStack {
                Spacer()

                Text(toast.message)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.72))
                    .clipShape(Capsule())
                    .padding(.bottom, 100)
            }
            .transition(.opacity)
            .animation(.easeOut(duration: 0.25), value: toastManager.currentToast?.id)
            .allowsHitTesting(false) // Toast 不拦截底层触摸
        }
    }
}
