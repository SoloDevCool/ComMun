# Example Hello World Plugin

这是一个示例插件，用于演示 Commun 插件系统的功能。

## 功能

1. **前台导航注入** - 在前台导航栏添加"示例插件"菜单
2. **后台导航注入** - 在后台导航栏添加"示例统计"菜单
3. **视图注入** - 在首页内容区域顶部显示问候横幅
4. **钩子监听** - 在帖子创建时记录日志

## 配置项

- `greeting_message` - 问候语内容（默认：Hello from Commun!）
- `show_greeting` - 是否显示问候横幅（默认：true）

## 文件说明

| 文件 | 说明 |
|------|------|
| `plugin.json` | 插件元数据 |
| `init.rb` | 入口文件，插件加载时执行 |
| `hooks.json` | 钩子注册配置 |
| `config_schema.json` | 配置项定义 |
| `lib/` | 插件代码 |
| `views/` | 插件视图（本示例未使用） |
