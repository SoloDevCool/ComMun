class CreateInstructors < ActiveRecord::Migration[8.1]
  def change
    create_table :instructors do |t|
      t.string :name
      t.string :title
      t.text :bio
      t.integer :sort_order
      t.boolean :is_active

      t.timestamps
    end
  end
end
