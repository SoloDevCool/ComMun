class Kol < ApplicationRecord
  validates :name, presence: true

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(sort_order: :asc, id: :asc) }

  PLATFORM_ICONS = {
    "微信公众号" => "bi-chat-dots-fill",
    "哔哩哔哩" => "bi-tv",
    "小红书" => "bi-book-half",
    "抖音" => "bi-music-note-beamed",
  }.freeze

  def platforms_list
    list = platforms.is_a?(Array) ? platforms : []
    list.map { |p| p.is_a?(Hash) ? p : { "name" => p.to_s, "url" => "" } }
  end

  def platform_icon(name)
    PLATFORM_ICONS[name] || "bi-globe2"
  end
end
