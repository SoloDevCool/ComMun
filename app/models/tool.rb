class Tool < ApplicationRecord
  belongs_to :tool_category

  validates :name, presence: true, length: { maximum: 100 }
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "请输入有效的 URL 地址", allow_blank: true }
  validates :icon_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "请输入有效的图标 URL 地址", allow_blank: true }, length: { maximum: 500 }
  validates :description, length: { maximum: 500 }
  validates :pricing, length: { maximum: 50 }

  scope :active, -> { where(is_active: true) }
  scope :sorted, -> { order(sort_order: :asc, id: :asc) }

  before_save :normalize_tags

  def normalize_tags
    self.tags = Array(tags).map(&:to_s).reject(&:blank?).uniq if tags_changed?
  end

  def display_icon_url
    icon_url
  end

  def has_custom_icon?
    icon_url.present?
  end
end
