class AddPublishedByOperationalToTopics < ActiveRecord::Migration[8.1]
  def change
    add_column :topics, :published_by_operational, :boolean, default: false, null: false
    add_index :topics, :published_by_operational, where: "(published_by_operational = true)"
  end
end
