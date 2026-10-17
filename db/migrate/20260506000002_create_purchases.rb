class CreatePurchases < ActiveRecord::Migration[8.1]
  def change
    create_table :purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :shop_item, null: false, foreign_key: true
      t.integer :points_cost, null: false, default: 0
      t.string :status, null: false, default: "completed"
      t.jsonb :delivered_data, default: {}
      t.datetime :completed_at
      t.timestamps
    end

    add_index :purchases, [:user_id, :shop_item_id]
    add_index :purchases, :status
  end
end
