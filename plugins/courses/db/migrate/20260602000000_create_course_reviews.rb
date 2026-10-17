class CreateCourseReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :course_reviews do |t|
      t.bigint :course_id, null: false
      t.string :user_name, null: false
      t.integer :rating, default: 5, null: false
      t.text :content, null: false
      t.integer :sort_order, default: 0, null: false
      t.boolean :is_active, default: true, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index :course_id
      t.index [:sort_order, :id]
    end

    add_foreign_key :course_reviews, :courses, on_delete: :cascade
  end
end
