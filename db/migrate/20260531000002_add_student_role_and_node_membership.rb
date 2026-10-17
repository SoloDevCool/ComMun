class AddStudentRoleAndNodeMembership < ActiveRecord::Migration[8.1]
  def up
    # 创建 users_role 枚举类型（如果不存在）
    unless enum_type_exists?('users_role')
      execute <<-SQL.squish
        CREATE TYPE users_role AS ENUM ('user', 'vip', 'operator', 'admin', 'student')
      SQL
    else
      # 如果枚举类型已存在，添加 student 值
      execute <<-SQL.squish
        ALTER TYPE users_role ADD VALUE IF NOT EXISTS 'student'
      SQL
    end

    # 如果 users 表的 role 列还不是枚举类型，则转换它
    if column_type('users', 'role') != 'users_role'
      execute <<-SQL.squish
        ALTER TABLE users ALTER COLUMN role TYPE users_role USING role::text::users_role
      SQL
    end

    # 创建用户版块学员关联表
    create_table :user_node_memberships do |t|
      t.bigint :user_id, null: false
      t.bigint :node_id, null: false
      t.datetime :joined_at, null: false
      t.datetime :expires_at
      t.text :notes

      t.timestamps

      t.index [:user_id, :node_id], unique: true
      t.index :node_id
    end

    add_foreign_key :user_node_memberships, :users, on_delete: :cascade
    add_foreign_key :user_node_memberships, :nodes, on_delete: :cascade
  end

  def down
    drop_table :user_node_memberships

    # 移除 student 角色枚举值
    execute <<-SQL.squish
      ALTER TYPE users_role RENAME TO users_role_old
    SQL

    execute <<-SQL.squish
      CREATE TYPE users_role AS ENUM ('user', 'vip', 'operator', 'admin')
    SQL

    execute <<-SQL.squish
      ALTER TABLE users ALTER COLUMN role TYPE users_role USING role::text::users_role
    SQL

    execute <<-SQL.squish
      DROP TYPE users_role_old
    SQL
  end

  private

  def enum_type_exists?(type_name)
    result = execute <<-SQL.squish
      SELECT 1 FROM pg_type WHERE typname = '#{type_name}'
    SQL
    result.to_a.any?
  end

  def column_type(table, column)
    result = execute <<-SQL.squish
      SELECT data_type FROM information_schema.columns
      WHERE table_name = '#{table}' AND column_name = '#{column}'
    SQL
    result.first&.dig('data_type')&.downcase
  end
end