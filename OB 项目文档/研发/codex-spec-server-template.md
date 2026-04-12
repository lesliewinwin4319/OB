# [功能名称] — 服务端 Codex Spec

> **使用说明（Seth 填写后删除此块）**
> 本文档是交给 Codex 的实现规格。每个字段都必须填写完整，不能有"待定"或模糊描述。
> Codex 只实现这里写的内容，不会自行补充或推断。

---

## Meta

| 字段 | 内容 |
|---|---|
| Spec ID | SERVER-XXX |
| 作者 | Seth |
| 日期 | YYYY-MM-DD |
| 目标目录 | `ob-server/` 或 `server/` |
| 关联需求 | [PRD 链接或需求描述] |

---

## 一句话目标

> 用一句话说清楚这个 Spec 要实现什么。例：为用户添加头像上传接口，接受 multipart/form-data，存储到 OSS 并更新 DB。

---

## 范围

**包含（In Scope）**
- [ ] 列出每一项要实现的内容

**不包含（Out of Scope）**
- [ ] 明确列出不做的事，防止 Codex 过度实现

---

## 涉及文件

> 列出所有需要新建或修改的文件。Codex 只动这些文件。

| 操作 | 文件路径 |
|---|---|
| 新建 | `src/xxx/xxx.ts` |
| 修改 | `src/xxx/xxx.module.ts` |
| 新建 Migration | `src/database/migrations/YYYYMMDDHHMMSS-描述.ts` |

---

## 数据库变更

> 如无 DB 变更，写"无"。

### 新增 / 修改字段

```
表名: users
新增字段:
  - avatar_url: varchar(500), nullable, default null
```

### Migration 要求

- Migration 文件名格式：`YYYYMMDDHHMMSS-add-avatar-url-to-users.ts`
- 必须实现 `up()` 和 `down()`
- `down()` 必须能完全回滚 `up()` 的变更

---

## DTO 定义

> 列出所有新增或修改的 DTO，包含每个字段的类型、是否必填、校验规则。

```typescript
// UpdateProfileDto
class UpdateProfileDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(20)
  nickname: string;          // 必填，1-20字符

  @IsUrl()
  @IsOptional()
  avatarUrl?: string;        // 选填，合法 URL
}
```

---

## Entity 变更

> 如有 Entity 字段变更，列出完整的字段定义（不是整个 Entity，只写变更部分）。

```typescript
// 在 User Entity 中新增：
@Column({ nullable: true, length: 500 })
avatarUrl: string | null;
```

---

## 业务逻辑

> 用步骤描述每个 Service 方法的逻辑。要精确到"先做什么、再做什么、失败时抛什么错"。

### `UsersService.updateProfile(userId, dto)`

1. 根据 `userId` 查询用户，不存在则抛 `NotFoundException`
2. 更新 `nickname`（必填）
3. 如果 `dto.avatarUrl` 存在，更新 `avatarUrl`
4. 保存并返回更新后的 user 对象
5. 不使用事务（单表操作不需要）

---

## API 接口

> 每个接口单独描述。格式固定，不能省略任何字段。

### `PATCH /api/v1/users/profile`

| 项目 | 内容 |
|---|---|
| Guards | `JwtAuthGuard`, `ProfileCompleteGuard`（根据需求决定是否加） |
| Request Header | `Authorization: Bearer <token>` |
| Request Body | `UpdateProfileDto` |
| 成功响应码 | 200 |
| 成功响应体 | `{ data: { id, nickname, avatarUrl, status } }` |
| 失败场景 | 401 未登录；404 用户不存在；400 参数校验失败 |

---

## Module 注册

> 列出需要在哪个 Module 里注册新的 Provider / Controller / Import。

```typescript
// UsersModule 需要：
// - 确认已有 TypeORM.forFeature([User])
// - 无需新增 import
```

---

## 验收标准

> Codex 完成后，Louis/Seth 用这个列表做 Code Review 检查。每条必须可验证。

- [ ] `PATCH /api/v1/users/profile` 接口存在，路径正确
- [ ] 未携带 JWT 时返回 401
- [ ] `nickname` 为空时返回 400
- [ ] `nickname` 超过 20 字符时返回 400
- [ ] 成功时返回 200，响应体包含更新后的 `nickname`
- [ ] Migration `up()` 和 `down()` 均已实现
- [ ] 没有引入任何 Spec 范围之外的改动
