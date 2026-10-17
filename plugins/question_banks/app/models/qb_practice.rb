class QbPractice < ApplicationRecord
  belongs_to :user
  belongs_to :qb_exam
  has_many :qb_answers, dependent: :destroy

  validates :mode, presence: true

  scope :completed, -> { where(completed: true) }
  scope :by_mode, ->(mode) { where(mode: mode) }
  scope :recent, -> { order(created_at: :desc) }

  MODE_LABELS = { "daily" => "每日一练", "chapter" => "章节练习", "exam" => "试卷模式", "wrong" => "错题本" }.freeze

  def mode_label
    MODE_LABELS[mode] || mode
  end

  def accuracy
    return 0 if total_count.zero?
    (correct_count.to_f / total_count * 100).round(1)
  end
end
