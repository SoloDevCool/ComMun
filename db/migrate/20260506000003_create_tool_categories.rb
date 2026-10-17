class CreateToolCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :tool_categories do |t|
      t.string :name, null: false
      t.string :icon
      t.string :color, default: "#6366f1"
      t.text :description
      t.integer :sort_order, default: 0
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :tool_categories, :sort_order
  end
end
