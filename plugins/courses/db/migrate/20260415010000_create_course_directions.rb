class CreateCourseDirections < ActiveRecord::Migration[8.1]
  def change
    create_table :course_directions do |t|
      t.string :name, null: false
      t.integer :sort_order, default: 0, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :course_directions, :name, unique: true
    add_index :course_directions, :sort_order
  end
end
