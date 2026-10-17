class AddBanFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :banned_at, :datetime
    add_column :users, :ban_expires_at, :datetime
    add_column :users, :ban_reason, :string
    add_column :users, :banned_by_id, :bigint
    add_index :users, :banned_by_id
    add_index :users, :banned_at
    add_index :users, :ban_expires_at
  end
end
