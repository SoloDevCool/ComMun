class UserNodeMembership < ApplicationRecord
  belongs_to :user
  belongs_to :node

  validates :user_id, uniqueness: { scope: :node_id, message: "已经是该版块的学员" }

  # 检查是否已过期
  def expired?
    expires_at.present? && expires_at < Time.current
  end

  # 检查是否有效
  def active?
    !expired?
  end

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at < ?", Time.current) }
end