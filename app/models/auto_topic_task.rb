class AutoTopicTask < ApplicationRecord
  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }, default: :pending

  validates :scheduled_date, :scheduled_at, presence: true

  scope :for_date, ->(date) { where(scheduled_date: date) }
  scope :today, -> { for_date(Date.current) }
  scope :recent, -> { order(scheduled_at: :desc) }

  belongs_to :topic, optional: true
  belongs_to :draft, class_name: "TopicDraft", optional: true

  def processing!
    update!(status: :processing)
  end

  def completed!(topic_title:, topic_id: nil, draft_id: nil, action: nil)
    update!(
      status: :completed,
      topic_title: topic_title,
      topic_id: topic_id,
      draft_id: draft_id,
      action: action || self.action
    )
  end

  def failed!(error_message)
    update!(status: :failed, error_message: error_message.truncate(500))
  end
end
