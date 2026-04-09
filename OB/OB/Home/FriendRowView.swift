// FriendRowView.swift
// OB App - 好友列表单行 Cell：头像 + 昵称 + 选中态指示
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-08

import SwiftUI

// MARK: - FriendRowView

/// 好友列表中的单行视图
/// 选中时背景变为 #F5F5F5，未选中时透明
struct FriendRowView: View {

    let friend: Friend
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 头像（复用 AvatarView）
            AvatarView(
                imageURL: nil,
                name: friend.nickname,
                backgroundColor: Color(hex: friend.avatarColor),
                size: 40
            )

            // 昵称
            Text(friend.nickname)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color(hex: "#333333"))

            Spacer()

            // 选中态勾选图标
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "#333333"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? Color(hex: "#F5F5F5") : Color.clear)
        .contentShape(Rectangle()) // 扩大可点击区域
    }
}
