class CpsAd < ApplicationRecord
  has_many :click_logs, class_name: "CpsAdClickLog", dependent: :destroy

  validates :title, presence: true
  validates :link_url, presence: true

  scope :active, -> { where(is_active: true).order(sort_order: :asc) }

  def self.rotate(session)
    ads = active.to_a
    return nil if ads.empty?

    index = session[:cps_ad_index].to_i % ads.size
    session[:cps_ad_index] = index + 1
    ads[index]
  end
end
