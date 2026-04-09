// Friend.swift
// OB App - 好友数据模型
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-08

import Foundation

// MARK: - Friend

/// 好友模型
/// 使用 [Friend] 数组管理选中状态，为未来多选预留扩展空间
struct Friend: Identifiable, Hashable {
    let id: String
    let nickname: String
    let avatarColor: String  // hex 颜色，复用 AvatarView 的字母头像
}
