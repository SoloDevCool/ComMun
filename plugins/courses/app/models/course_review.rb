class CourseReview < ApplicationRecord
  belongs_to :course

  validates :user_name, presence: true, length: { maximum: 50 }
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :content, presence: true, length: { minimum: 2, maximum: 500 }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:sort_order, :created_at) }

  after_initialize :set_default_rating, if: :new_record?

  private

  def set_default_rating
    self.rating ||= 5
  end
end
