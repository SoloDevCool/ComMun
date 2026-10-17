class AddVipOnlyToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :vip_only, :boolean
  end
end
