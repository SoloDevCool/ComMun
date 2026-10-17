class CreateKols < ActiveRecord::Migration[8.1]
  def change
    create_table :kols do |t|
      t.string :name, null: false
      t.text :bio
      t.string :email
      t.string :price
      t.string :avatar
      t.json :platforms, default: []
      t.integer :sort_order, default: 0, null: false
      t.boolean :is_active, default: true, null: false
      t.timestamps
    end
  end
end
