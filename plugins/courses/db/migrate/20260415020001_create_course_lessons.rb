class CreateCourseLessons < ActiveRecord::Migration[8.1]
  def change
    create_table :course_lessons do |t|
      t.string :title, null: false
      t.string :duration
      t.string :lesson_type, null: false, default: "video"
      t.boolean :is_free, default: false, null: false
      t.integer :sort_order, default: 0, null: false
      t.references :course_chapter, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :course_lessons, :lesson_type
  end
end
