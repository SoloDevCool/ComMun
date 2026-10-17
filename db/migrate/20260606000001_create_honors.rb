class CreateHonors < ActiveRecord::Migration[8.1]
  def change
    create_table :honors do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :certificate_image
      t.text :description
      t.date :awarded_at
      t.integer :sort_order, default: 0, null: false
      t.boolean :is_active, default: true, null: false
      t.timestamps
    end

    add_index :honors, :sort_order
    add_index :honors, :is_active
  end
end
