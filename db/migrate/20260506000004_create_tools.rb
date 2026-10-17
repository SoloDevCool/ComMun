class CreateTools < ActiveRecord::Migration[8.1]
  def change
    create_table :tools do |t|
      t.references :tool_category, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :url
      t.string :icon
      t.string :color, default: "#6366f1"
      t.string :pricing
      t.jsonb :tags, default: []
      t.integer :sort_order, default: 0
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :tools, :sort_order
  end
end
