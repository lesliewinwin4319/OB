// AvatarView.swift
// OB App - 动态头像组件（Initials Avatar）
// 作者：Louis（iOS 客户端）
// 版本：v1.0 · 2026-04-04

import SwiftUI

// MARK: - 莫兰迪色盘

/// 低饱和度莫兰迪背景色，进入资料页时随机选取一次后固定
struct MorandiPalette {
    static let colors: [Color] = [
        Color(hex: "#B5C0D0"),  // 雾蓝
        Color(hex: "#CCD3CA"),  // 浅苔绿
        Color(hex: "#F5E8DD"),  // 暖米白
        Color(hex: "#EED3D9"),  // 玫瑰粉
        Color(hex: "#D4C5B0"),  // 驼色
        Color(hex: "#C9C0D3"),  // 薰衣草紫
    ]

    static func random() -> Color {
        colors.randomElement()!
    }
}

// MARK: - 字符提取逻辑

/// 从昵称中提取头像显示字符，遵循 PRD §2 五种规则：
/// 1. 中文：首个汉字
/// 2. 英文/拉丁：首字母强制大写
/// 3. 数字：首位数字
/// 4. Emoji：首个 Emoji（含复合 Emoji 完整提取）
/// 5. 其他（阿拉伯文、泰文、纯标点等）：展示「?」兜底
func extractAvatarChar(from text: String) -> String {
    guard !text.isEmpty, let firstChar = text.first else { return "?" }

    let scalar = firstChar.unicodeScalars.first!

    // 规则 4：Emoji 判断（优先于其他规则）
    // isEmoji 属性在 Unicode 13+ 对大量符号为 true，增加 value > 0x238C 过滤掉键帽等符号
    if scalar.properties.isEmoji && scalar.value > 0x238C {
        // 使用 Character 确保组合 Emoji（如肤色修饰符、家庭 Emoji）被完整取出
        return String(firstChar)
    }

    // 规则 1：中文汉字（CJK 统一汉字基本区 + 扩展常用区）
    let value = scalar.value
    let isCJK = (value >= 0x4E00 && value <= 0x9FFF)   // 基本汉字
             || (value >= 0x3400 && value <= 0x4DBF)   // 扩展 A
             || (value >= 0x20000 && value <= 0x2A6DF)  // 扩展 B
    if isCJK {
        return String(firstChar)
    }

    // 规则 2：英文字母（ASCII 范围 a-z / A-Z）
    if firstChar.isLetter && scalar.value <= 0x007A {
        return String(firstChar).uppercased()
    }

    // 规则 3：数字（0-9）
    if firstChar.isNumber && scalar.value >= 0x0030 && scalar.value <= 0x0039 {
        return String(firstChar)
    }

    // 规则 5：其他字符（阿拉伯文、泰文、纯标点等）兜底
    return "?"
}

// MARK: - AvatarView

/// 动态头像组件
/// - 优先展示网络头像图片（imageURL 非 nil 且加载成功）
/// - 无图时展示由昵称生成的 Initials 头像
/// - 背景色由外部传入（由 ProfileSetupViewModel 在 init 时固定随机，此后不变）
struct AvatarView: View {
    let imageURL: String?      // 微信头像 URL（可为 nil）
    let name: String           // 当前输入的昵称，实时计算显示字符
    let backgroundColor: Color // 莫兰迪背景色，外部传入以确保固定不变
    var size: CGFloat = 80     // 头像尺寸，默认 80pt

    var body: some View {
        Group {
            if let urlString = imageURL, let url = URL(string: urlString), !urlString.isEmpty {
                // 有头像 URL：异步加载网络图片
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        // 加载失败降级为 Initials 头像
                        initialsView
                    case .empty:
                        // 加载中：展示灰色占位
                        Color(hex: "#E8E8E8")
                    @unknown default:
                        initialsView
                    }
                }
            } else {
                // 无头像 URL：展示 Initials 头像
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    // MARK: - Initials 头像

    private var initialsView: some View {
        ZStack {
            backgroundColor
            Text(extractAvatarChar(from: name))
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Preview

#Preview("各类昵称场景") {
    let bgColor = MorandiPalette.random()
    return VStack(spacing: 20) {
        HStack(spacing: 16) {
            AvatarView(imageURL: nil, name: "杰哥",  backgroundColor: bgColor)
            AvatarView(imageURL: nil, name: "Alice", backgroundColor: Color(hex: "#CCD3CA"))
            AvatarView(imageURL: nil, name: "123",   backgroundColor: Color(hex: "#F5E8DD"))
        }
        HStack(spacing: 16) {
            AvatarView(imageURL: nil, name: "😊🎉",  backgroundColor: Color(hex: "#EED3D9"))
            AvatarView(imageURL: nil, name: "!@#",  backgroundColor: Color(hex: "#D4C5B0"))
            AvatarView(imageURL: nil, name: "",     backgroundColor: Color(hex: "#C9C0D3"))
        }
    }
    .padding()
}
