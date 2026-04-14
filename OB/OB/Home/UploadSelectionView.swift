// UploadSelectionView.swift
// OB App - 上传选择页：选择好友 + 微信分享 + 申请提交
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-08

import SwiftUI

// MARK: - UploadSelectionView

/// 上传选择页
/// 布局从上到下：
/// 1. 顶部栏（X + 标题）
/// 2. Token 选择框
/// 3. "已经注册OB的好友" + 好友列表
/// 4. "其他" + 微信分享按钮
/// 5. 底部"申请"按钮
struct UploadSelectionView: View {

    let hashableImage: HashableImage
    @Binding var navigationPath: NavigationPath

    @State private var selectedFriends: [Friend] = []
    @State private var friends: [Friend] = MockData.friends
    @StateObject private var viewModel: UploadViewModel

    /// 放弃二次确认弹窗
    @State private var showDiscardAlert = false

    /// 申请按钮是否可用
    private var canSubmit: Bool {
        !selectedFriends.isEmpty && !viewModel.isSubmitting
    }

    init(hashableImage: HashableImage, navigationPath: Binding<NavigationPath>) {
        self.hashableImage = hashableImage
        self._navigationPath = navigationPath
        self._viewModel = StateObject(wrappedValue: UploadViewModel(hashableImage: hashableImage))
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: 顶部栏
                HStack {
                    Button(action: {
                        showDiscardAlert = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color(hex: "#333333"))
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Text("上传到谁的主页？")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(hex: "#333333"))

                    Spacer()

                    // 占位，保持标题居中
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                // MARK: Token 选择框
                FriendTokenBar(selectedFriends: $selectedFriends)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // MARK: 好友列表区域
                if !friends.isEmpty {
                    // 小标题
                    HStack {
                        Text("已经注册OB的好友")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#999999"))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                    Divider()
                        .padding(.horizontal, 16)

                    // 好友列表
                    FriendListView(
                        friends: friends,
                        selectedFriends: $selectedFriends
                    )
                }

                // MARK: 其他区域（微信分享）
                HStack {
                    Text("其他")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#999999"))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 8)

                Divider()
                    .padding(.horizontal, 16)

                // 微信分享按钮
                Button(action: {
                    ToastManager.shared.show("功能开发中，敬请期待")
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: "#07C160")) // 微信绿
                        Text("微信分享")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color(hex: "#333333"))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }

                Spacer()

                // MARK: 底部申请按钮
                Button(action: {
                    guard let selectedFriend = selectedFriends.first else { return }
                    Task {
                        await viewModel.submit(friend: selectedFriend, navigationPath: $navigationPath)
                    }
                }) {
                    Group {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("申请")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: "#333333"))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .opacity(canSubmit ? 1.0 : 0.3)
                .disabled(!canSubmit)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .disableSwipeBack()
        .alert("确定要放弃吗？", isPresented: $showDiscardAlert) {
            Button("否", role: .cancel) {}
            Button("是", role: .destructive) {
                navigationPath = NavigationPath()
            }
        }
    }
}
