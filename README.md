# OB App

> 一个反自拍社交 App — 朋友拍你，你来审核，真实出现在彼此的主页。

本项目由 AI 团队全程辅助开发，用于展示当前 AI 在全栈软件工程领域的实际能力。

---

## 项目结构

```
OB/                  iOS 客户端（Swift / SwiftUI）
ob-server/           服务端（NestJS / PostgreSQL / Redis）
OB 项目文档/          产品文档、技术方案、测试用例、日报
```

## 技术栈

| 端 | 技术 |
|----|------|
| iOS | Swift 6 / SwiftUI / Xcode 26 |
| 后端 | NestJS / PostgreSQL 16 / Redis / JWT |
| 架构 | RESTful API / Snowflake UID / BullMQ |

## 本地运行

### 后端

```bash
cd ob-server
cp .env.example .env   # 填写你的配置
npm install
npm run start:dev
```

### iOS

用 Xcode 打开 `OB/OB.xcodeproj`，选择模拟器，Cmd+R 运行。

## AI 团队

| 角色 | 职责 |
|------|------|
| Adam | 项目总监（Claude Code） |
| Louis | iOS 客户端开发 |
| Seth | 服务端开发 |
| Rock | QA 测试 |
