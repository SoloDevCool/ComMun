class CreateCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :courses do |t|
      t.string :title, null: false
      t.text :description
      t.string :direction, null: false, default: "前端开发"
      t.string :difficulty, null: false, default: "入门"
      t.integer :lessons_count, default: 0, null: false
      t.string :duration
      t.integer :students_count, default: 0, null: false
      t.string :author
      t.string :color, default: "#6366f1"
      t.string :icon, default: "bi-book"
      t.string :cover_url
      t.integer :sort_order, default: 0, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :courses, :direction
    add_index :courses, :difficulty
    add_index :courses, :is_active
    add_index :courses, :sort_order
  end
end
