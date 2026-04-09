// View+DisableSwipeBack.swift
// OB App - 禁用 iOS 侧滑返回手势的 ViewModifier
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-08

import SwiftUI

// MARK: - DisableSwipeBackModifier

/// 通过查找 UINavigationController 并禁用其 interactivePopGestureRecognizer 实现
/// 仅在 View appear 时禁用，disappear 时恢复
private struct DisableSwipeBackModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .background(SwipeBackDisabler())
    }
}

// MARK: - SwipeBackDisabler (UIViewControllerRepresentable)

private struct SwipeBackDisabler: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> DisableSwipeBackViewController {
        DisableSwipeBackViewController()
    }

    func updateUIViewController(_ uiViewController: DisableSwipeBackViewController, context: Context) {}
}

private class DisableSwipeBackViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}

// MARK: - View Extension

extension View {
    /// 禁用当前页面的 iOS 侧滑返回手势
    func disableSwipeBack() -> some View {
        modifier(DisableSwipeBackModifier())
    }
}
