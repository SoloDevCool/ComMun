class QbExam < ApplicationRecord
  has_many :qb_questions, -> { order(:sort_order) }, dependent: :destroy
  has_many :qb_practices, dependent: :destroy

  validates :name, :code, :level, presence: true
  validates :code, uniqueness: true

  scope :ordered, -> { order(:sort_order, :id) }
  scope :by_level, ->(level) { where(level: level) }

  def question_count
    qb_questions.approved.count
  end
end
