// UIApplication+TopNav.swift
// OB App - 获取当前最顶层 UINavigationController 的工具扩展
// 供 FriendGuideView 禁用侧滑手势使用

import UIKit

extension UIApplication {
    /// 从 key window 向下找到最顶层的 UINavigationController
    var topNavigationController: UINavigationController? {
        guard let windowScene = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        return findTopNavController(from: rootVC)
    }

    private func findTopNavController(from vc: UIViewController) -> UINavigationController? {
        if let nav = vc as? UINavigationController {
            return nav
        }
        if let presented = vc.presentedViewController {
            return findTopNavController(from: presented)
        }
        // 处理 UITabBarController 等容器
        for child in vc.children {
            if let nav = findTopNavController(from: child) {
                return nav
            }
        }
        return nil
    }
}
