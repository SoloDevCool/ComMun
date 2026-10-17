class Course < ApplicationRecord
  has_one_attached :cover
  belongs_to :instructor, optional: true
  has_many :course_chapters, dependent: :destroy
  has_many :course_lessons, through: :course_chapters
  has_many :course_permissions, dependent: :destroy
  has_many :authorized_users, through: :course_permissions, source: :user
  has_many :course_reviews, dependent: :destroy

  DIFFICULTIES = {
    "入门" => "入门",
    "进阶" => "进阶",
    "高级" => "高级"
  }.freeze

  validates :title, presence: true, length: { maximum: 200 }
  validates :description, length: { maximum: 1000 }
  validates :direction, presence: true
  validate :direction_must_exist
  validates :difficulty, presence: true, inclusion: { in: DIFFICULTIES.keys }
  validates :lessons_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :students_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :duration, length: { maximum: 50 }
  validates :author, length: { maximum: 100 }
  validates :color, length: { maximum: 20 }
  validates :icon, length: { maximum: 50 }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(sort_order: :asc, id: :asc) }
  scope :by_direction, ->(direction) { where(direction: direction) if direction.present? }
  scope :by_difficulty, ->(difficulty) { where(difficulty: difficulty) if difficulty.present? }

  def direction_label
    direction
  end

  def difficulty_label
    DIFFICULTIES[difficulty] || difficulty
  end

  def difficulty_css_class
    case difficulty
    when "入门" then "beginner"
    when "进阶" then "intermediate"
    when "高级" then "advanced"
    else ""
    end
  end

  private

  def direction_must_exist
    return if direction.blank?
    unless CourseDirection.active.exists?(name: direction)
      errors.add(:direction, "所选方向不存在或已禁用")
    end
  end
end
