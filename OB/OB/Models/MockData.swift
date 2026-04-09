// MockData.swift
// OB App - Mock 数据（好友列表 + 模拟 API）
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-08

import Foundation

// MARK: - MockData

enum MockData {

    /// Mock 好友列表（两个测试好友）
    static let friends: [Friend] = [
        Friend(id: "mock_001", nickname: "杰哥", avatarColor: "#B5C0D0"),
        Friend(id: "mock_002", nickname: "肉肉", avatarColor: "#D4A5A5"),
    ]

    // MARK: - Mock API

    /// 模拟提交共创申请
    /// 0.5s 延迟后返回成功，不发真实网络请求
    static func submitRequest(friendID: String) async -> Bool {
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        return true
    }
}
