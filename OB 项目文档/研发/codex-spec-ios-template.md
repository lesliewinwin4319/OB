# [功能名称] — iOS 客户端 Codex Spec

> **使用说明（Louis 填写后删除此块）**
> 本文档是交给 Codex 的实现规格。每个字段都必须填写完整，不能有"待定"或模糊描述。
> Codex 只实现这里写的内容，不会自行推断交互细节或补充功能。

---

## Meta

| 字段 | 内容 |
|---|---|
| Spec ID | IOS-XXX |
| 作者 | Louis |
| 日期 | YYYY-MM-DD |
| 目标目录 | `OB/` |
| 关联需求 | [PRD 链接或需求描述] |

---

## 一句话目标

> 用一句话说清楚这个 Spec 要实现什么。例：实现编辑个人资料页面，包含昵称输入和头像选择，提交后调用服务端接口并更新本地状态。

---

## 范围

**包含（In Scope）**
- [ ] 列出每一项要实现的内容

**不包含（Out of Scope）**
- [ ] 明确列出不做的事

---

## 涉及文件

> 列出所有需要新建或修改的文件。Codex 只动这些文件。

| 操作 | 文件路径 |
|---|---|
| 新建 | `OB/Features/Profile/EditProfileView.swift` |
| 新建 | `OB/Features/Profile/EditProfileViewModel.swift` |
| 修改 | `OB/App/MainTabView.swift` |

---

## 数据模型

> 描述新增或修改的 Swift struct/class/enum。

```swift
// 新增
struct UserProfile: Codable {
    let id: String
    let nickname: String
    let avatarUrl: String?
    let status: UserStatus
}

enum UserStatus: String, Codable {
    case pendingProfile = "PENDING_PROFILE"
    case active = "ACTIVE"
}
```

---

## 网络层

> 列出每个新增的 API 调用，精确到 URL、Method、请求体、响应体结构。

### `updateProfile(nickname:)`

```
Method:  PATCH
URL:     /api/v1/users/profile
Headers: Authorization: Bearer <token>
Body:    { "nickname": String }
成功响应: 200, { "data": { "id", "nickname", "avatarUrl", "status" } }
失败响应: 400 参数错误 / 401 未登录
```

> API 调用统一放在 `OB/Network/APIClient.swift`（如已存在则在该文件中新增方法）。

---

## 页面 / 组件

> 每个 View 单独描述。明确说明布局结构、每个 UI 元素的行为、状态变化。

### `EditProfileView`

**布局结构**
```
VStack
  ├── 顶部导航栏：标题"编辑资料"，右侧"保存"按钮
  ├── 头像区域：圆形占位图（本期不可点击，显示灰色默认头像）
  └── 昵称输入框：TextField，placeholder "请输入昵称"，最多20字符
```

**状态**
```swift
@State private var nickname: String = ""      // 绑定输入框
@State private var isLoading: Bool = false    // 保存中时禁用按钮并显示 ProgressView
@State private var errorMessage: String? = nil // 非 nil 时在输入框下方显示红色错误文字
```

**交互逻辑**
1. 页面出现时，昵称输入框预填当前用户昵称（从 ViewModel 读取）
2. 点击"保存"：
   - `nickname` 为空 → `errorMessage = "昵称不能为空"`，不发请求
   - `nickname` 超过 20 字 → `errorMessage = "昵称最多20个字符"`，不发请求
   - 校验通过 → `isLoading = true`，调用 `viewModel.save()`
3. 保存成功 → dismiss 当前页面
4. 保存失败 → `isLoading = false`，`errorMessage = "保存失败，请重试"`

---

## ViewModel

> 描述 ViewModel 的职责、属性和方法。

### `EditProfileViewModel`

```swift
@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var currentNickname: String = ""
    
    // 调用 API，成功返回 true，失败返回 false
    func save(nickname: String) async -> Bool
}
```

**`save()` 内部逻辑：**
1. 调用 `APIClient.updateProfile(nickname:)`
2. 成功：更新本地存储的用户信息（如有 UserSession 单例则更新其 nickname），返回 `true`
3. 失败（网络错误 / 服务端 4xx）：打印错误 log，返回 `false`

---

## 导航接入

> 说明这个页面从哪里进入，用什么方式跳转（NavigationLink / sheet / fullScreenCover）。

- 从 `ProfileView` 的右上角"编辑"按钮进入
- 使用 `.sheet` 方式弹出
- 保存成功后调用 `dismiss()`

---

## 验收标准

> Codex 完成后，Louis 用这个列表做 Code Review 检查。每条必须可验证。

- [ ] `EditProfileView` 可以从 `ProfileView` 以 sheet 方式打开
- [ ] 昵称输入框预填当前昵称
- [ ] 昵称为空时点保存，显示错误提示，不发请求
- [ ] 昵称超过 20 字时显示错误提示，不发请求
- [ ] 保存中按钮禁用，显示加载状态
- [ ] 保存成功后 dismiss 页面
- [ ] 保存失败显示错误提示
- [ ] 没有引入任何 Spec 范围之外的改动
