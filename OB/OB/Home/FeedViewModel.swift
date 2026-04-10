// FeedViewModel.swift
// OB App - 朋友圈业务逻辑
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-09

import SwiftUI
import Combine

// MARK: - FeedViewModel

/// 朋友圈数据流管理器
/// 处理数据加载、下拉刷新、分页加载以及点赞交互逻辑
final class FeedViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var posts: [Post] = []
    @Published var isRefreshing = false
    @Published var isLoadingMore = false
    @Published var hasMore = false // Mock 阶段固定为 false
    @Published var error: String?
    
    // MARK: - Initialization
    
    init() {
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// 首次加载或下拉刷新
    func refresh() async {
        guard !isRefreshing else { return }
        
        await MainActor.run {
            isRefreshing = true
            error = nil
        }
        
        // 模拟网络延迟
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
        
        await MainActor.run {
            // 在 Mock 阶段，重置为原始 5 条数据
            self.posts = Post.mockPosts
            self.isRefreshing = false
        }
    }
    
    /// 加载更多（分页）
    func loadMore() async {
        guard !isLoadingMore && hasMore else { return }
        
        await MainActor.run {
            isLoadingMore = true
        }
        
        // 模拟分页加载延迟
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
        
        await MainActor.run {
            // Mock 阶段暂不处理分页加载
            isLoadingMore = false
            hasMore = false
        }
    }
    
    /// 滚动到顶部（由 TabBar 重击触发）
    func scrollToTop() {
        // 这里需要配合 View 层的 ScrollViewProxy
        NotificationCenter.default.post(name: .feedScrollToTop, object: nil)
    }
    
    /// 点赞操作
    /// - Parameters:
    ///   - postId: 帖子 ID
    ///   - fromDoubleTap: 是否由双击触发
    ///     - 双击且已点赞：动画由 View 层播放，但数字不变（PRD P5：不取消赞）
    ///     - 双击未点赞 / 按钮点击：正常 toggle
    func toggleLike(for postId: String, fromDoubleTap: Bool = false) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            var post = posts[index]
            if fromDoubleTap && post.isLiked {
                // 已点赞时双击：只播动画，数字和状态不变
            } else if post.isLiked {
                post.isLiked = false
                post.likeCount -= 1
            } else {
                post.isLiked = true
                post.likeCount += 1
            }
            posts[index] = post
        }

        // TODO: 调用后端 API
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() {
        self.posts = Post.mockPosts
    }
}

// MARK: - Notifications

extension NSNotification.Name {
    static let feedScrollToTop = NSNotification.Name("feedScrollToTop")
}
