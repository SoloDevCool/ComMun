class TopicEnergyUnlock < ApplicationRecord
  belongs_to :topic
  belongs_to :user

  validates :topic_id, uniqueness: { scope: [:user_id, :block_index] }
  validates :block_index, presence: true
  validates :energy_cost, presence: true, numericality: { greater_than: 0, only_integer: true }
end
