class CreateCpsAds < ActiveRecord::Migration[8.1]
  def change
    create_table :cps_ads do |t|
      t.string :title, null: false
      t.text :description
      t.string :image_url
      t.string :link_url, null: false
      t.integer :sort_order, default: 0, null: false
      t.boolean :is_active, default: true, null: false
      t.timestamps
    end

    add_index :cps_ads, :sort_order
    add_index :cps_ads, :is_active
  end
end
