class CreateCourseChapters < ActiveRecord::Migration[8.1]
  def change
    create_table :course_chapters do |t|
      t.string :title, null: false
      t.integer :sort_order, default: 0, null: false
      t.references :course, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
