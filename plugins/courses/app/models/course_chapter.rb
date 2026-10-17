class CourseChapter < ApplicationRecord
  belongs_to :course
  has_many :course_lessons, dependent: :destroy

  validates :title, presence: true, length: { maximum: 200 }

  scope :ordered, -> { order(sort_order: :asc, id: :asc) }
end
