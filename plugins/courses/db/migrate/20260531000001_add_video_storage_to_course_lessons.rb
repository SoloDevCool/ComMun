class AddVideoStorageToCourseLessons < ActiveRecord::Migration[8.1]
  def change
    add_column :course_lessons, :video_storage, :string, default: 'vod'
    add_column :course_lessons, :video_filename, :string
  end
end
