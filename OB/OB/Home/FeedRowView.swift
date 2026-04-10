// FeedRowView.swift
// OB App - 朋友圈单条帖子卡片
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-09

import SwiftUI

// MARK: - FeedRowView

struct FeedRowView: View {
    let post: Post
    let onLike: (Bool) -> Void // Bool indicates if it was a double tap
    let onAvatarTapped: (Post.User) -> Void
    let onImageTapped: (Post) -> Void
    
    @State private var showHeartAnimation = false
    /// 用于单击延迟，以便双击手势能先取消单击（解决 SwiftUI 单双击冲突）
    @State private var pendingSingleTapWorkItem: DispatchWorkItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: 被拍人信息
            HStack(spacing: 10) {
                Button(action: { onAvatarTapped(post.subject) }) {
                    if let avatarUrl = post.subject.avatarUrl {
                        AsyncImage(url: URL(string: avatarUrl)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color(hex: post.subject.avatarColor)
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(hex: post.subject.avatarColor))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(post.subject.nickname.prefix(1))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                    }
                }
                
                Button(action: { onAvatarTapped(post.subject) }) {
                    Text(post.subject.nickname)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: "#1A1A1A"))
                }
                
                Spacer()
                
                // 时间戳
                Text(timeAgoDisplay(post.timestamp))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.gray)
            }
            .padding(.horizontal, 16)
            
            // Image Section: 帖子图片
            ZStack {
                AsyncImage(url: URL(string: post.imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit() // Bug3修复：.fill → .scaledToFit，保证原图纵横比自适应高度
                } placeholder: {
                    Rectangle()
                        .fill(Color(hex: "#EEEEEE"))
                        .aspectRatio(4/5, contentMode: .fit)
                        .overlay(ProgressView())
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                // Bug1修复：用计时器延迟单击，让双击有机会先取消它，避免 SwiftUI 双击时同时触发单击
                .onTapGesture(count: 2) {
                    pendingSingleTapWorkItem?.cancel()
                    pendingSingleTapWorkItem = nil
                    handleDoubleTap()
                }
                .onTapGesture {
                    let item = DispatchWorkItem { onImageTapped(post) }
                    pendingSingleTapWorkItem = item
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: item)
                }

                // Bug2修复：双击动画改为心形图标（hand.thumbsup.fill → heart.fill）
                if showHeartAnimation {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.red)
                        .shadow(radius: 10)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(1)
                }
            }
            
            // Footer: 拍照人 & 点赞
            HStack(alignment: .center) {
                // 拍照人信息
                HStack(spacing: 4) {
                    Text("By")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.gray)
                    
                    Button(action: { onAvatarTapped(post.author) }) {
                        Text("@\(post.author.nickname)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "#1A1A1A"))
                    }
                }
                
                Spacer()
                
                // 点赞按钮
                Button(action: { onLike(false) }) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 18))
                            .foregroundStyle(post.isLiked ? Color(hex: "#1A1A1A") : Color.gray)
                        
                        if post.likeCount > 0 {
                            Text("\(post.likeCount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "#1A1A1A"))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .padding(.vertical, 12)
        .background(Color.white)
    }
    
    // MARK: - Helpers
    
    private func handleDoubleTap() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showHeartAnimation = true
        }
        onLike(true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.2)) {
                showHeartAnimation = false
            }
        }
    }
    
    private func timeAgoDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian) // 强制公历，避免部分系统语言设置下显示佛历
        formatter.dateFormat = "yyyy/M/dd HH:mm"
        return "拍摄于\(formatter.string(from: date))"
    }
}

// MARK: - Preview

#Preview {
    FeedRowView(
        post: Post.mockPosts[0],
        onLike: { _ in },
        onAvatarTapped: { _ in },
        onImageTapped: { _ in }
    )
}
