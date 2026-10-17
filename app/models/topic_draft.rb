class TopicDraft < ApplicationRecord
  belongs_to :node
  belongs_to :user

  validates :title, presence: true, length: { minimum: 4, maximum: 120 }
  validates :content, presence: true, length: { minimum: 10 }
  validates :node, presence: true
  validates :source_url, presence: true,
    format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "请输入有效的 URL 地址" },
    if: :is_repost?

  scope :recent, -> { order(updated_at: :desc) }
end
