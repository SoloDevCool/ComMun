class CourseDirection < ApplicationRecord
  has_many :courses, foreign_key: :direction, primary_key: :name, dependent: :nullify

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(sort_order: :asc, id: :asc) }

  # 返回所有有效方向名称列表（用于校验）
  def self.active_names
    active.pluck(:name)
  end
end
