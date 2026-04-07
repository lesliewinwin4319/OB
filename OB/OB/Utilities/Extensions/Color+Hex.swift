// Color+Hex.swift
// OB App - Color 十六进制初始化扩展
// 供 AvatarView 莫兰迪色盘使用

import SwiftUI

extension Color {
    /// 通过十六进制字符串（支持 "#RRGGBB" 或 "RRGGBB"）创建 Color
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: Double
        switch hex.count {
        case 6: // RGB (RRGGBB)
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8)  & 0xFF) / 255.0
            b = Double( int        & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1 // 解析失败兜底为白色
        }
        self.init(red: r, green: g, blue: b)
    }
}
