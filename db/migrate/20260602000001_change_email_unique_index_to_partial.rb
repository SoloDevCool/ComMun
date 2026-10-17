class ChangeEmailUniqueIndexToPartial < ActiveRecord::Migration[8.1]
  def change
    # 移除原有全量唯一索引，改为部分唯一索引（排除空字符串）
    # 这样用户名注册时多个用户可以同时 email 为空字符串
    remove_index :users, :email, if_exists: true
    add_index :users, :email, unique: true, where: "email != ''", name: "index_users_on_email"
  end
end
