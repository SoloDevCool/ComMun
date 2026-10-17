class AddInstructorToCourses < ActiveRecord::Migration[8.1]
  def change
    add_reference :courses, :instructor, foreign_key: true
  end
end
