// MockData.swift
// OB App - Mock 数据（好友列表 + 模拟 API）
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-08

import Foundation

// MARK: - MockData

enum MockData {

    /// Mock 好友列表（两个测试好友）
    static let friends: [Friend] = [
        Friend(id: "mock_001", uid: "mock_uid_001", nickname: "杰哥", avatarColor: "#B5C0D0"),
        Friend(id: "mock_002", uid: "mock_uid_002", nickname: "肉肉", avatarColor: "#D4A5A5"),
    ]
}
