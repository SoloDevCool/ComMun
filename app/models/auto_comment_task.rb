class AutoCommentTask < ApplicationRecord
  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }, default: :pending

  validates :scheduled_date, :scheduled_at, presence: true

  scope :for_date, ->(date) { where(scheduled_date: date) }
  scope :today, -> { for_date(Date.current) }
  scope :recent, -> { order(scheduled_at: :desc) }

  belongs_to :topic, optional: true
  belongs_to :comment, optional: true

  def processing!
    update!(status: :processing)
  end

  def completed!(comment_content:, topic_id: nil, comment_id: nil)
    update!(
      status: :completed,
      comment_content: comment_content,
      topic_id: topic_id,
      comment_id: comment_id
    )
  end

  def failed!(error_message)
    update!(status: :failed, error_message: error_message.truncate(500))
  end
end
