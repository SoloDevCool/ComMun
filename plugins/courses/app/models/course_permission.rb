class CoursePermission < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :user_id, uniqueness: { scope: :course_id, message: "已存在该课程的授权记录" }
end
