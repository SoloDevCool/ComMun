class AddContentToCourseLessons < ActiveRecord::Migration[8.1]
  def change
    add_column :course_lessons, :content, :text
  end
end
