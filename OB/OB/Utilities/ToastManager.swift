// ToastManager.swift
// OB App - 全局 Toast 管理器（单例）
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-07

import SwiftUI
import Combine

// MARK: - ToastItem

/// Toast 数据模型
struct ToastItem: Identifiable, Equatable {
    let id: UUID
    let message: String
}

// MARK: - ToastManager

/// 全局单例 Toast 管理器
/// 使用方式：ToastManager.shared.show("消息内容")
/// 视图层在 OBApp.swift 根层级覆盖 ToastView，监听 currentToast 变化
@MainActor
final class ToastManager: ObservableObject {

    static let shared = ToastManager()

    @Published var currentToast: ToastItem? = nil

    private var dismissTask: Task<Void, Never>? = nil

    private init() {}

    /// 显示 Toast
    /// - Parameters:
    ///   - message: 提示文案
    ///   - duration: 持续时间（默认 1.5s）
    func show(_ message: String, duration: TimeInterval = 1.5) {
        // 取消上一次的自动消失任务（新 Toast 覆盖旧 Toast）
        dismissTask?.cancel()

        currentToast = ToastItem(id: UUID(), message: message)

        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

            if !Task.isCancelled {
                dismiss()
            }
        }
    }

    /// 立即关闭 Toast
    func dismiss() {
        currentToast = nil
        dismissTask?.cancel()
        dismissTask = nil
    }
}
