// ImageViewer.swift
// OB App - 朋友圈大图查看器（支持缩放、拖拽与关闭）
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-09

import SwiftUI

// MARK: - ImageViewer

struct ImageViewer: View {
    let imageUrl: String
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    /// 用于单击延迟，以便双击手势能先取消单击（解决 SwiftUI 单双击冲突）
    @State private var pendingSingleTapWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            // 背景层：整个黑色区域都可点击关闭（letterbox 区域同样响应）
            Color.black.ignoresSafeArea()
                .onTapGesture {
                    let item = DispatchWorkItem { onDismiss() }
                    pendingSingleTapWorkItem = item
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: item)
                }

            // 图片主体
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(magnificationGesture)
                    .gesture(dragGesture)
                    // Bug4修复：添加双击缩放（复刻原生相册行为）+ 解决单双击冲突
                    .onTapGesture(count: 2) {
                        pendingSingleTapWorkItem?.cancel()
                        pendingSingleTapWorkItem = nil
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if scale > 1.0 {
                                // 已放大 → 还原
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                // 未放大 → 放大 2.0x
                                scale = 2.0
                            }
                        }
                    }
                    .onTapGesture {
                        // 延迟执行，让双击有机会先取消
                        let item = DispatchWorkItem { onDismiss() }
                        pendingSingleTapWorkItem = item
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: item)
                    }
            } placeholder: {
                ProgressView()
                    .tint(.white)
            }
            
            // 关闭按钮
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Circle().fill(.black.opacity(0.3)))
                    }
                    .padding(.top, 44)
                    .padding(.leading, 20)
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .statusBarHidden(true)
        .transition(.opacity)
    }
    
    // MARK: - Gestures
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale *= delta
            }
            .onEnded { _ in
                lastScale = 1.0
                if scale < 1.0 {
                    withAnimation(.spring()) {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
                // 如果图片比例为 1 且正在向下拖拽，考虑触发 dismiss (可选交互)
                if scale == 1.0 && offset.height > 100 {
                    onDismiss()
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ImageViewer(imageUrl: "https://picsum.photos/id/1011/800/1000", onDismiss: {})
}
