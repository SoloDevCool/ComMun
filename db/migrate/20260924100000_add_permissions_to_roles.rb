# 角色支持配置权限点：
#   - roles 增加 permissions (jsonb) 存储权限点 key 数组，["*"] 表示全部权限
#   - 内置角色预设：admin 全部权限；operator 预设后台内容类权限点
class AddPermissionsToRoles < ActiveRecord::Migration[8.1]
  OPERATOR_PRESET = %w[
    admin.dashboard
    admin.content.moderate
    admin.content.manage
    admin.logs.view
    topic.manage_any
    comment.manage_any
    shop.manage
    courses.manage
  ].freeze

  def up
    add_column :roles, :permissions, :jsonb, null: false, default: []

    Role.reset_column_information
    Role.where(key: "admin").update_all(permissions: ["*"])
    Role.where(key: "operator").update_all(permissions: OPERATOR_PRESET)
  end

  def down
    remove_column :roles, :permissions
  end
end
