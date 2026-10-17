# 权限点（Permission Point）目录
#
# 权限点 = 一个细粒度的能力标识（如 "admin.users.manage"、"shop.manage"）。
# 角色通过勾选权限点获得对应能力，代码中用 user.can?("xxx") 检查。
#
# 来源：
#   1. 核心权限点 —— 本文件 CORE 常量定义
#   2. 插件权限点 —— 插件通过以下两种方式注册（key 自动加插件标识前缀，如 "shop.manage"）：
#      a) plugin.json 中声明： "permissions": [{ "key": "manage", "name": "商城管理" }]
#      b) init.rb / 钩子脚本中调用： register_permission key: "manage", name: "商城管理"
#
# 通配符：角色的 permissions 包含 "*" 时拥有全部权限点（内置 admin 即此配置）。
class Permission
  CORE = [
    { key: "admin.dashboard",        name: "后台总览",   group: "核心" },
    { key: "admin.users.manage",     name: "用户管理",   group: "核心" },
    { key: "admin.roles.manage",     name: "角色管理",   group: "核心" },
    { key: "admin.settings.manage",  name: "系统设置",   group: "核心" },
    { key: "admin.logs.view",        name: "日志查看",   group: "核心" },
    { key: "admin.content.moderate", name: "内容审核",   group: "核心" },
    { key: "admin.content.manage",   name: "内容管理",   group: "核心" },
    { key: "admin.demo.data",        name: "演示数据",   group: "核心" },
    { key: "topic.manage_any",       name: "管理任意主题", group: "前台" },
    { key: "comment.manage_any",     name: "管理任意评论", group: "前台" }
  ].freeze

  def self.core
    CORE
  end

  # 插件注册的权限点（已带插件前缀）
  def self.plugin
    Myapp::PluginManager.instance.plugin_permissions
  end

  def self.all
    core + plugin
  end

  def self.valid_key?(key)
    all.any? { |p| p[:key] == key.to_s } || key.to_s == "*"
  end

  # 按来源分组：{ "核心权限" => [...], "商城（shop）" => [...] }
  def self.grouped
    groups = { "核心权限" => core.dup }
    plugin.each do |p|
      label = p[:plugin_name] ? "#{p[:plugin_name]}（#{p[:plugin_id]}）" : p[:plugin_id].to_s
      groups[label] ||= []
      groups[label] << p
    end
    groups
  end
end
