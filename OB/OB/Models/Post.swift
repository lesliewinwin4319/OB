// Post.swift
// OB App - 朋友圈帖子数据模型
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-09

import Foundation

// MARK: - Post

/// 朋友圈帖子模型
struct Post: Identifiable, Hashable {
    let id: String
    
    /// 被拍的人（同意被拍并显示在卡片顶部的用户）
    let subject: User
    
    /// 拍照人（在卡片底部以 @xxx 形式展示的用户）
    let author: User
    
    /// 图片 URL
    let imageUrl: String
    
    /// 拍摄时间（提交申请的时间）
    let timestamp: Date
    
    /// 是否已点赞
    var isLiked: Bool
    
    /// 点赞数
    var likeCount: Int
    
    /// 用户简版信息
    struct User: Identifiable, Hashable {
        let id: String
        let nickname: String
        let avatarUrl: String?
        let avatarColor: String // 兜底颜色
    }
}

// MARK: - Mock Data Extension

extension Post {
    static var mockPosts: [Post] {
        let now = Date()
        return [
            Post(
                id: "1",
                subject: User(id: "u1", nickname: "小明", avatarUrl: "https://picsum.photos/id/101/200/200", avatarColor: "#FFB5B5"),
                author: User(id: "u2", nickname: "杰哥", avatarUrl: "https://picsum.photos/id/102/200/200", avatarColor: "#B5D1FF"),
                imageUrl: "https://picsum.photos/id/1011/800/1000",
                timestamp: now.addingTimeInterval(-3600),
                isLiked: false,
                likeCount: 12
            ),
            Post(
                id: "2",
                subject: User(id: "u3", nickname: "莉莉", avatarUrl: "https://picsum.photos/id/103/200/200", avatarColor: "#D1FFB5"),
                author: User(id: "u4", nickname: "阿强", avatarUrl: "https://picsum.photos/id/104/200/200", avatarColor: "#F3B5FF"),
                imageUrl: "https://picsum.photos/id/1012/800/1200",
                timestamp: now.addingTimeInterval(-7200),
                isLiked: true,
                likeCount: 45
            ),
            Post(
                id: "3",
                subject: User(id: "u5", nickname: "张三", avatarUrl: nil, avatarColor: "#FFEB3B"),
                author: User(id: "u1", nickname: "小明", avatarUrl: "https://picsum.photos/id/101/200/200", avatarColor: "#FFB5B5"),
                imageUrl: "https://picsum.photos/id/1013/1000/800",
                timestamp: now.addingTimeInterval(-86400),
                isLiked: false,
                likeCount: 8
            ),
            Post(
                id: "4",
                subject: User(id: "u6", nickname: "李四", avatarUrl: "https://picsum.photos/id/106/200/200", avatarColor: "#8BC34A"),
                author: User(id: "u7", nickname: "王五", avatarUrl: "https://picsum.photos/id/107/200/200", avatarColor: "#00BCD4"),
                imageUrl: "https://picsum.photos/id/1014/800/800",
                timestamp: now.addingTimeInterval(-172800),
                isLiked: false,
                likeCount: 2
            ),
            Post(
                id: "5",
                subject: User(id: "u8", nickname: "赵六", avatarUrl: "https://picsum.photos/id/108/200/200", avatarColor: "#E91E63"),
                author: User(id: "u9", nickname: "孙七", avatarUrl: "https://picsum.photos/id/109/200/200", avatarColor: "#9C27B0"),
                imageUrl: "https://picsum.photos/id/1015/800/1000",
                timestamp: now.addingTimeInterval(-259200),
                isLiked: true,
                likeCount: 99
            )
        ]
    }
}
