class AddVipOnlyToTopics < ActiveRecord::Migration[8.1]
  def change
    add_column :topics, :vip_only, :boolean
  end
end
