// FriendTokenBar.swift
// OB App - 好友选择框组件（Token 模式）
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-08

import SwiftUI

// MARK: - FriendTokenBar

/// Token 选择框：展示已选好友为 @好友名 [x] 样式
/// 无选中时展示占位文案
struct FriendTokenBar: View {

    @Binding var selectedFriends: [Friend]

    var body: some View {
        HStack(spacing: 8) {
            if selectedFriends.isEmpty {
                // 占位文案
                Text("选择好友")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "#999999"))
            } else {
                // Token 列表
                ForEach(selectedFriends) { friend in
                    tokenView(for: friend)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#F8F8F8"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Token 视图

    private func tokenView(for friend: Friend) -> some View {
        HStack(spacing: 4) {
            Text("@\(friend.nickname)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#333333"))

            // X 按钮：取消选择的唯一路径
            Button(action: {
                selectedFriends.removeAll(where: { $0.id == friend.id })
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#999999"))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: "#E0E0E0"), lineWidth: 1)
        )
    }
}
