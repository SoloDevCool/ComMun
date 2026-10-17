class QbQuestion < ApplicationRecord
  belongs_to :qb_exam
  belongs_to :user, optional: true
  has_many :qb_answers, dependent: :nullify

  validates :content, presence: true
  validates :answer, presence: true

  scope :ordered, -> { order(:sort_order, :id) }
  scope :approved, -> { where(status: "approved") }
  scope :pending_review, -> { where(status: "pending") }
  scope :rejected, -> { where(status: "rejected") }
  scope :by_user, -> { where.not(user_id: nil) }

  STATUS_LABELS = { "pending" => "待审核", "approved" => "已通过", "rejected" => "已拒绝" }.freeze

  QUESTION_TYPE_LABELS = { 0 => "单选题", 1 => "多选题", 2 => "判断题" }.freeze

  def question_type_label
    QUESTION_TYPE_LABELS[question_type] || "单选题"
  end

  def status_label
    STATUS_LABELS[status] || status
  end

  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  def approve!(reviewer_id = nil)
    update!(status: "approved", reviewed_at: Time.current, reviewed_by: reviewer_id, rejection_reason: nil)
  end

  def reject!(reason = nil, reviewer_id = nil)
    update!(status: "rejected", reviewed_at: Time.current, reviewed_by: reviewer_id, rejection_reason: reason)
  end

  def as_json_for_practice
    {
      id: id,
      type: question_type_label,
      category: category,
      content: content,
      options: options,
      answer: answer,
      explanation: explanation
    }
  end
end
