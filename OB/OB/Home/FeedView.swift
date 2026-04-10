// FeedView.swift
// OB App - 朋友圈主视图（信息流展示）
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-09

import SwiftUI

// MARK: - UIScrollView KVO 下拉刷新检测器
// 直接观察底层 UIScrollView.contentOffset，比 SwiftUI PreferenceKey 方案可靠

private class PullDetectorUIView: UIView {
    var onPull: ((CGFloat) -> Void)?
    private var observation: NSKeyValueObservation?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // didMoveToWindow 在完整视图层级建立后调用，比 didMoveToSuperview 更可靠
        // 再延迟一个 runloop 确保 SwiftUI 的 UIScrollView 已就位
        DispatchQueue.main.async { [weak self] in
            self?.attachToScrollView()
        }
    }

    private func attachToScrollView() {
        guard observation == nil else { return }
        var v: UIView? = superview
        while let current = v {
            if let scrollView = current as? UIScrollView {
                observation = scrollView.observe(\.contentOffset, options: .new) { [weak self] sv, _ in
                    let pullAmount = max(-sv.contentOffset.y, 0)
                    self?.onPull?(pullAmount)
                }
                return
            }
            v = current.superview
        }
    }
}

private struct PullToRefreshDetector: UIViewRepresentable {
    let onPull: (CGFloat) -> Void

    func makeUIView(context: Context) -> PullDetectorUIView {
        let view = PullDetectorUIView()
        view.onPull = onPull
        return view
    }

    func updateUIView(_ uiView: PullDetectorUIView, context: Context) {}
}

// MARK: - FeedView

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    let onNavigateToProfile: (Post.User) -> Void

    @State private var selectedPostForViewer: Post?
    @State private var refreshTriggered = false
    @State private var pullAmount: CGFloat = 0

    private let refreshThreshold: CGFloat = 50

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                // KVO 检测器放在 ScrollView 内容的最顶层，才能往上找到父级 UIScrollView
                PullToRefreshDetector { amount in
                    pullAmount = amount
                    if amount > refreshThreshold && !viewModel.isRefreshing && !refreshTriggered {
                        refreshTriggered = true
                        Task {
                            await viewModel.refresh()
                            refreshTriggered = false
                            pullAmount = 0
                        }
                    }
                }
                .frame(height: 1)

                LazyVStack(spacing: 8) {

                    // loading 菊花
                    if viewModel.isRefreshing || pullAmount > refreshThreshold {
                        ProgressView()
                            .padding(.top, 4)
                            .transition(.opacity)
                    }

                    // 顶部占位：为叠在上方的 TopNavigationBar 留出空间
                    Color.clear
                        .frame(height: 60)
                        .id("feedTop")

                    ForEach(viewModel.posts) { post in
                        FeedRowView(
                            post: post,
                            onLike: { isDoubleTap in
                                viewModel.toggleLike(for: post.id, fromDoubleTap: isDoubleTap)
                            },
                            onAvatarTapped: { user in
                                onNavigateToProfile(user)
                            },
                            onImageTapped: { tappedPost in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedPostForViewer = tappedPost
                                }
                            }
                        )
                        .id(post.id)
                    }

                    Text("到底啦")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#999999"))
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                }
            }
            .background(Color(hex: "#F7F7F7"))
            .onReceive(NotificationCenter.default.publisher(for: .feedScrollToTop)) { _ in
                withAnimation(.spring()) {
                    proxy.scrollTo("feedTop", anchor: .top)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .fullScreenCover(item: $selectedPostForViewer) { post in
            ImageViewer(imageUrl: post.imageUrl) {
                selectedPostForViewer = nil
            }
        }
    }
}

// MARK: - ProfilePlaceholderView

struct ProfilePlaceholderView: View {
    let user: Post.User
    let onDismiss: () -> Void

    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white.ignoresSafeArea()

            // 返回按钮
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(12)
            }
            .padding(.top, 52)
            .padding(.leading, 8)

            // 页面内容
            VStack(spacing: 12) {
                Text(user.nickname)
                    .font(.title2.bold())
                Text("待开发")
                    .font(.system(size: 16))
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // 右滑返回手势
        .offset(x: max(dragOffset, 0))
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if value.translation.width > 0 {
                        state = value.translation.width
                    }
                }
                .onEnded { value in
                    if value.translation.width > 100 {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            onDismiss()
                        }
                    }
                }
        )
    }
}

// MARK: - Preview

#Preview {
    FeedView(viewModel: FeedViewModel(), onNavigateToProfile: { _ in })
}
