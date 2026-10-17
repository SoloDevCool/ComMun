class Instructor < ApplicationRecord
  has_one_attached :avatar_file
  has_many :courses, dependent: :nullify

  validates :name, presence: true, length: { maximum: 50 }
  validates :title, length: { maximum: 100 }
  validates :bio, length: { maximum: 500 }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(sort_order: :asc, id: :asc) }

  def avatar_url
    if avatar_file.attached?
      Rails.application.routes.url_helpers.rails_blob_path(avatar_file, only_path: true, disposition: "inline")
    elsif avatar.present?
      avatar
    else
      nil
    end
  end
end
