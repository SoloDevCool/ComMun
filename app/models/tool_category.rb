class ToolCategory < ApplicationRecord
  has_many :tools, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }

  scope :active, -> { where(is_active: true) }
  scope :sorted, -> { order(sort_order: :asc, id: :asc) }

  def tools_count
    tools.active.count
  end
end
