class ChangeNodesIconToText < ActiveRecord::Migration[8.1]
  def up
    # icon 字段改为 text，支持直接存储 SVG 代码
    change_column :nodes, :icon, :text
  end

  def down
    change_column :nodes, :icon, :string
  end
end
