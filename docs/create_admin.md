# 创建默认管理员账号

## 概述

通过 Rake 任务创建默认管理员账号，支持交互式输入和环境变量两种模式，适用于本地开发和 Docker 容器。

## 脚本位置

`lib/tasks/create_admin.rake`

## 运行方式

### 方式一：交互式运行（本地开发推荐）

```bash
cd myapp
bundle exec rails admin:create
```

运行后会依次提示输入：

1. 邮箱（默认 `admin@example.com`）
2. 用户名（默认 `admin`）
3. 密码（需输入两次确认，至少 6 位）

### 方式二：环境变量指定（Docker / CI 推荐）

```bash
# 交互模式：缺少的环境变量会交互提示
ADMIN_EMAIL=admin@example.com ADMIN_USERNAME=admin ADMIN_PASSWORD=123456 \
  bundle exec rails admin:create

# 静默模式：所有参数必须通过环境变量指定，无交互
ADMIN_EMAIL=admin@example.com ADMIN_USERNAME=admin ADMIN_PASSWORD=123456 \
  bundle exec rails admin:create_silent
```

### 方式三：在 Docker 容器中运行

```bash
# 方式 A：进入容器后执行
docker exec -it <container_name> bash
bundle exec rails admin:create

# 方式 B：直接执行（适合自动化）
docker exec -it <container_name> \
  env ADMIN_EMAIL=admin@example.com ADMIN_USERNAME=admin ADMIN_PASSWORD=123456 \
  bundle exec rails admin:create_silent
```

## 环境变量

| 变量 | 说明 | 必填 | 默认值 |
|------|------|------|--------|
| `ADMIN_EMAIL` | 管理员邮箱 | `create_silent` 必填 | 交互输入，默认 `admin@example.com` |
| `ADMIN_USERNAME` | 管理员用户名 | `create_silent` 必填 | 交互输入，默认 `admin` |
| `ADMIN_PASSWORD` | 管理员密码 | `create_silent` 必填 | 必须交互输入，至少 6 位 |

## 行为逻辑

| 场景 | 行为 |
|------|------|
| 邮箱不存在 | 创建新的管理员账号 |
| 邮箱已存在且已是管理员 | 跳过，提示无需重复创建 |
| 邮箱已存在但非管理员 | 升级该账号角色为 `admin`，并更新密码 |

## 两个任务的对比

| 特性 | `admin:create` | `admin:create_silent` |
|------|----------------|----------------------|
| 交互式输入 | 支持（环境变量缺失时提示） | 不支持 |
| 环境变量 | 可选 | 必填 |
| 适用场景 | 本地开发、手动操作 | Docker、CI/CD 自动化 |
