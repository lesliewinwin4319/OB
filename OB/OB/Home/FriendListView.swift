// FriendListView.swift
// OB App - 好友列表组件：展示已注册 OB 的好友
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-08

import SwiftUI

// MARK: - FriendListView

/// 好友列表，支持单选（本期限制 count < 1 拦截）
/// 交互规则：
/// - 无选中：点击选中
/// - 已选中 1 人：点击其他人 -> Toast 提示
/// - 已选中：再次点击同一人 -> 无反应（取消只能通过 Token X 按钮）
struct FriendListView: View {

    let friends: [Friend]
    @Binding var selectedFriends: [Friend]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(friends) { friend in
                FriendRowView(
                    friend: friend,
                    isSelected: selectedFriends.contains(where: { $0.id == friend.id })
                )
                .onTapGesture {
                    handleTap(friend)
                }

                // 分隔线（最后一项不加）
                if friend.id != friends.last?.id {
                    Divider()
                        .padding(.leading, 68) // 头像宽度 40 + spacing 12 + 左 padding 16
                }
            }
        }
    }

    // MARK: - 点击处理

    private func handleTap(_ friend: Friend) {
        // 已经选中的好友，再次点击无反应
        if selectedFriends.contains(where: { $0.id == friend.id }) {
            return
        }

        // 单选拦截：已选中 1 人时，点击其他人 Toast 提示
        if selectedFriends.count >= 1 {
            ToastManager.shared.show("只支持选择一名好友哦")
            return
        }

        // 选中好友
        selectedFriends.append(friend)
    }
}
