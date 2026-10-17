class Node < ApplicationRecord
  has_many :topics, dependent: :destroy
  has_many :node_follows, dependent: :destroy
  has_many :followers, through: :node_follows, source: :user
  has_many :user_node_memberships, dependent: :destroy
  has_many :student_users, -> { active }, through: :user_node_memberships, source: :user

  has_one_attached :icon_file

  attribute :kind, default: "interest"
  enum :kind, { system: "system", interest: "interest" }

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_-]+\z/, message: "只能包含小写字母、数字、横线和下划线" }
  # Emoji/文字图标限 10 字符；SVG 代码图标放宽上限
  validates :icon, length: { maximum: 10 }, if: -> { icon.blank? || !icon_svg_code? }
  validates :icon, length: { maximum: 20_000 }, if: :icon_svg_code?

  # 判断 icon 是否为内联 SVG 代码
  def icon_svg_code?
    icon.to_s.strip.start_with?("<svg")
  end
  validates :position, presence: true, if: :system?
  validate :icon_file_must_be_valid, if: :icon_file_attached?

  # 获取裁剪后的图标 URL（正方形，自动居中裁剪）
  # SVG 为矢量格式，不做裁剪变体，直接使用原文件
  ICON_VARIANT_SIZE = 128
  SVG_CONTENT_TYPE = "image/svg+xml"

  def icon_file_variant
    return icon_file if icon_file_svg?
    icon_file.variant(resize_to_fill: [ICON_VARIANT_SIZE, ICON_VARIANT_SIZE]) if icon_file.attached?
  end

  def icon_file_svg?
    icon_file.attached? && icon_file.content_type == SVG_CONTENT_TYPE
  end

  # 排序范围
  scope :ordered, -> { order(position: :asc) }
  scope :system_ordered, -> { where(kind: :system).ordered }
  scope :interest_ordered, -> { where(kind: :interest).order(topics_count: :desc) }

  def kind_label
    self.class.kinds_i18n[kind.to_sym]
  end

  def self.kinds_i18n
    { system: "系统版块", interest: "兴趣版块" }
  end

  def to_param
    slug
  end

  def followed_by?(user)
    return false if user.nil?
    node_follows.exists?(user_id: user.id)
  end

  # 获取版块的学员数量
  def active_students_count
    user_node_memberships.active.count
  end

  private

  def icon_file_attached?
    icon_file.attached?
  end

  def icon_file_must_be_valid
    return unless icon_file.attached?

    allowed_types = ["image/png", "image/jpeg", "image/gif", "image/webp", SVG_CONTENT_TYPE]
    unless allowed_types.include?(icon_file.content_type)
      errors.add(:icon_file, "只支持 PNG、JPG、GIF、WebP、SVG 格式")
    end

    if icon_file.byte_size > 2.megabytes
      errors.add(:icon_file, "文件大小不能超过 2MB")
    end
  end
end
