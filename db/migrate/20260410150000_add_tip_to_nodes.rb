class AddTipToNodes < ActiveRecord::Migration[7.2]
  def change
    add_column :nodes, :tip, :text unless column_exists?(:nodes, :tip)
  end
end
