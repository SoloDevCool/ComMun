class Purchase < ApplicationRecord
  belongs_to :user
  belongs_to :shop_item

  validates :points_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true

  scope :completed, -> { where(status: "completed") }
  scope :recent, -> { order(created_at: :desc) }

  STATUSES = %w[pending completed failed refunded].freeze
  STATUS_LABELS = { "pending" => "待处理", "completed" => "已完成", "failed" => "失败", "refunded" => "已退款" }.freeze

  def status_label
    STATUS_LABELS[status] || status
  end

  def completed?
    status == "completed"
  end
end
