class AddIconUrlToTools < ActiveRecord::Migration[8.1]
  def change
    add_column :tools, :icon_url, :string
  end
end
