// PhotoFlowRoute.swift
// OB App - 拍照流程路由枚举（NavigationPath 用）
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-08

import SwiftUI

// MARK: - PhotoFlowRoute

/// 拍照 -> 确认 -> 上传选择 的路由枚举
/// 用于 NavigationPath 的类型安全路由
enum PhotoFlowRoute: Hashable {
    case confirmation(HashableImage)   // 拍照确认页，携带原图
    case uploadSelection(HashableImage) // 上传选择页，携带原图
}

// MARK: - HashableImage

/// UIImage 的 Hashable 包装
/// 基于对象指针（ObjectIdentifier）实现 Hashable，不对图片内容做 hash
/// 同一个 UIImage 实例始终 hash 相同，不同实例即使内容相同也不同
final class HashableImage: Hashable {
    let image: UIImage

    init(_ image: UIImage) {
        self.image = image
    }

    static func == (lhs: HashableImage, rhs: HashableImage) -> Bool {
        lhs.image === rhs.image
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(image))
    }
}
