// WebViewSheet.swift
// OB App - 用户协议 / 隐私政策 WebView Sheet 封装
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-04

import SwiftUI
import WebKit

// MARK: - WKWebView UIViewRepresentable 包装

/// 将 UIKit 的 WKWebView 桥接给 SwiftUI 使用
struct WebViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

// MARK: - WebViewSheet

/// 从登录页底部弹出的 Sheet，展示用户协议或隐私政策
/// 当前 URL 默认跳转百度（待正式上线替换为实际协议 URL）
struct WebViewSheet: View {
    let url: URL
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            WebViewRepresentable(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("关闭") {
                            isPresented = false
                        }
                        .foregroundStyle(.primary)
                    }
                }
        }
    }

    /// 根据 URL 推断标题（简单匹配，TODO: 待产品确认是否需要外部传入 title 参数）
    private var navigationTitle: String {
        let urlString = url.absoluteString.lowercased()
        if urlString.contains("privacy") {
            return "隐私政策"
        } else if urlString.contains("terms") || urlString.contains("agreement") {
            return "用户协议"
        }
        return "详情"
    }
}

// MARK: - Preview

#Preview {
    WebViewSheet(
        url: URL(string: "https://www.baidu.com")!,
        isPresented: .constant(true)
    )
}
