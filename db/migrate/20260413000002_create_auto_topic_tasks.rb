class CreateAutoTopicTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :auto_topic_tasks do |t|
      t.date :scheduled_date, null: false
      t.datetime :scheduled_at, null: false
      t.integer :status, default: 0, null: false
      t.string :action, default: "draft", null: false
      t.string :topic_title
      t.integer :topic_id
      t.integer :draft_id
      t.text :error_message
      t.timestamps

      t.index [:scheduled_date, :status]
    end
  end
end
