class CreateCoursePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :course_permissions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :course, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end

    add_index :course_permissions, [:user_id, :course_id], unique: true
  end
end
