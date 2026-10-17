# 版块学员角色功能说明

## 功能概述

本功能为 commun-server 项目新增了"版块学员"角色，学员只能在被授权的版块内进行发帖和交流，实现细粒度的权限控制。

## 功能特性

### 1. 学员角色
- 新增 `student` 角色
- 学员只能在已授权的版块中发帖和评论
- 支持设置版块权限的过期时间

### 2. 权限控制
- **发帖权限**：学员只能在自己所属的版块发帖
- **查看权限**：学员只能看到自己版块内的帖子
- **版块选择**：发帖时只能选择已授权的版块

### 3. 管理后台
- 管理员可以为用户添加学员角色
- 管理员可以为学员分配版块权限
- 支持设置版块权限的过期时间
- 支持添加备注信息

## 数据库变更

### 新增表：user_node_memberships

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键 |
| user_id | bigint | 用户ID |
| node_id | bigint | 版块ID |
| joined_at | datetime | 加入时间 |
| expires_at | datetime | 过期时间（可选） |
| notes | text | 备注信息 |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

### 修改表：users

- 在 role 枚举中添加 `student` 值

## 模型变更

### User 模型

新增关联：
```ruby
has_many :user_node_memberships, dependent: :destroy
has_many :member_nodes, through: :user_node_memberships, source: :node
```

新增方法：
- `student?` - 检查是否为学员
- `student_of?(node)` - 检查是否为指定版块的学员
- `accessible_nodes` - 获取可发帖的版块列表
- `can_post_to_node?(node)` - 检查是否可以发帖到指定版块
- `join_node_as_student!(node, expires_at:, notes:)` - 加入版块学员
- `leave_node_as_student!(node)` - 离开版块学员

### Node 模型

新增关联：
```ruby
has_many :user_node_memberships, dependent: :destroy
has_many :student_users, -> { active }, through: :user_node_memberships, source: :user
```

新增方法：
- `active_students_count` - 获取版块的学员数量

### UserNodeMembership 模型

新增模型用于管理用户-版块学员关系：
- `expired?` - 检查是否已过期
- `active?` - 检查是否有效
- 作用域：`active`（有效的）、`expired`（已过期的）

## 控制器变更

### TopicsController

修改方法：
- `new` - 学员只能看到已授权的版块
- `create` - 添加发帖权限检查
- `set_nodes` - 根据用户角色返回可用的版块列表
- `base_topics` - 学员只能看到自己版块的帖子

### Admin::UserNodeMembershipsController

新增控制器用于管理学员版块权限：
- `index` - 查看用户的版块权限
- `create` - 添加版块权限
- `destroy` - 移除版块权限

## 视图变更

### 管理后台用户列表

- 角色选择下拉框新增"版块学员"选项
- 为学员用户显示"版块权限"管理按钮

### 学员版块管理页面

- 显示用户已加入的版块列表
- 显示加入时间和过期时间
- 支持添加新版块权限
- 支持设置过期时间和备注

## 使用指南

### 1. 运行数据库迁移

```bash
cd commun-server
rails db:migrate
```

### 2. 创建学员用户

在管理后台的用户管理页面：
1. 找到要设置为学员的用户
2. 在角色下拉框中选择"版块学员"
3. 系统会自动保存角色变更

### 3. 分配版块权限

1. 在用户列表中，点击学员用户的"版块权限"按钮
2. 在弹出的页面中，选择要授权的版块
3. 可选：设置过期时间和备注
4. 点击"添加版块"完成授权

### 4. 学员发帖

- 学员登录后访问发帖页面
- 只能看到已被授权的版块
- 选择版块后正常发帖

## 权限逻辑

### 发帖权限检查

```ruby
# 在 TopicsController#create 中
if current_user.student? && !current_user.student_of?(@topic.node)
  @topic.errors.add(:node_id, "没有权限在该版块发帖")
  render :new, status: :forbidden
  return
end
```

### 内容查看控制

```ruby
# 在 TopicsController#base_topics 中
if user_signed_in? && current_user.student?
  query = query.where(node_id: current_user.member_node_ids)
end
```

## API 示例

### 将用户设置为学员并授权版块

```ruby
user = User.find(params[:user_id])
node = Node.find(params[:node_id])

# 设置角色
user.update!(role: 'student')

# 添加版块权限
user.join_node_as_student!(node, expires_at: 30.days.from_now, notes: '课程学员')
```

### 检查用户权限

```ruby
user = User.find(1)
node = Node.find(1)

# 检查是否为学员
user.student? # => true

# 检查是否可以发帖到指定版块
user.can_post_to_node?(node) # => true

# 获取可用的版块
user.accessible_nodes # => 返回用户可发帖的版块列表
```

## 注意事项

1. **过期时间**：如果设置了过期时间，过期后学员将无法在该版块发帖
2. **角色切换**：将用户从学员切换为其他角色时，版块权限关系保留，但不再生效
3. **删除版块**：删除版块时，关联的学员权限也会被级联删除
4. **已有帖子**：学员已有的帖子不会被删除，但无法查看其他版块的内容

## 扩展建议

未来可以考虑的扩展功能：
1. 学员等级系统（初级/中级/高级）
2. 学员发帖频率限制
3. 学员专属标签
4. 学员学习进度跟踪
5. 学员统计数据

## 技术栈

- Rails 8.1
- PostgreSQL
- Active Storage（如有需要）