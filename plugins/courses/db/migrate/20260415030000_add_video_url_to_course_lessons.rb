class AddVideoUrlToCourseLessons < ActiveRecord::Migration[8.1]
  def change
    add_column :course_lessons, :video_url, :string
  end
end
