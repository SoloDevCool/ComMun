class Honor < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
  validates :title, presence: true

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(sort_order: :asc, awarded_at: :desc, id: :asc) }

  # 用户显示名
  def display_name
    user&.display_name || '未知用户'
  end

  # 用户头像
  def avatar_url
    return nil unless user
    user.avatar_data_url
  rescue StandardError
    nil
  end
end
