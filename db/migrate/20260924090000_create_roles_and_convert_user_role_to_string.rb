# 自定义角色支持：
#   1. 新建 roles 表（角色由数据库定义，管理员可在后台增删改）
#   2. 预置 5 个内置角色（与原 enum 值一一对应）
#   3. users.role 从 Postgres 原生枚举 users_role 转为 string，
#      以支持任意自定义角色 key
class CreateRolesAndConvertUserRoleToString < ActiveRecord::Migration[8.1]
  BUILT_INS = {
    "user"     => ["普通用户", "bg-info", 0],
    "vip"      => ["付费会员", "bg-danger text-white", 10],
    "student"  => ["版块学员", "bg-success text-white", 15],
    "operator" => ["运营", "bg-primary text-white", 50],
    "admin"    => ["管理员", "bg-warning text-dark", 100]
  }.freeze

  def up
    create_table :roles do |t|
      t.string :key, null: false, comment: "角色标识（存入 users.role）"
      t.string :name, null: false, comment: "角色显示名称"
      t.string :badge_class, null: false, default: "bg-secondary text-white", comment: "Bootstrap 徽章 class"
      t.integer :level, null: false, default: 0, comment: "权限等级：>=50 可进后台内容管理，>=100 拥有管理员全部权限"
      t.boolean :built_in, null: false, default: false, comment: "内置角色不可删除"
      t.timestamps
    end
    add_index :roles, :key, unique: true

    # 转换 users.role 列类型（需先加载列信息）
    change_column :users, :role, :string, using: "role::text"
    execute "DROP TYPE IF EXISTS users_role"

    Role.reset_column_information
    BUILT_INS.each do |key, (name, badge, level)|
      Role.create!(key: key, name: name, badge_class: badge, level: level, built_in: true)
    end
  end

  def down
    execute "CREATE TYPE users_role AS ENUM ('user', 'vip', 'operator', 'admin', 'student')"
    # 自定义角色 key 不在枚举内时回退为普通用户
    execute <<~SQL
      ALTER TABLE users ALTER COLUMN role TYPE users_role
      USING CASE
        WHEN role IN ('user', 'vip', 'operator', 'admin', 'student') THEN role::users_role
        ELSE 'user'::users_role
      END
    SQL
    drop_table :roles
  end
end
