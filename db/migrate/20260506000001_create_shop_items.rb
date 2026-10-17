class CreateShopItems < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_items do |t|
      t.string :name, null: false
      t.text :description
      t.string :item_type, null: false, default: "virtual"
      t.integer :price, null: false, default: 0
      t.string :icon, default: "bi-gift"
      t.boolean :active, default: true
      t.integer :stock, default: -1
      t.integer :sort_order, default: 0
      t.jsonb :metadata, default: {}
      t.timestamps
    end
  end
end
