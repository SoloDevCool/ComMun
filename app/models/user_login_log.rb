class UserLoginLog < ApplicationRecord
  belongs_to :user

  validates :ip_address, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where(created_at: Date.current.all_day) }
  scope :last_days, ->(days) { where(created_at: days.days.ago..Time.current) }
  scope :by_province, ->(province) { where(province: province) }

  def location_text
    [ country, province, city ].select(&:present?).join(" / ")
  end
end
