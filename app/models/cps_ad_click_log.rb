class CpsAdClickLog < ApplicationRecord
  belongs_to :cps_ad
  belongs_to :user, optional: true

  validates :ip_address, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where(created_at: Date.current.all_day) }
  scope :for_ad, ->(cps_ad_id) { where(cps_ad_id: cps_ad_id) }

  def user_display_name
    user&.display_name || "匿名用户"
  end

  def location_text
    [ country, province, city ].select(&:present?).join(" / ")
  end
end
