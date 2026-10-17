class CreateAutoCommentTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :auto_comment_tasks do |t|
      t.date :scheduled_date, null: false
      t.datetime :scheduled_at, null: false
      t.integer :status, default: 0, null: false
      t.string :comment_content
      t.integer :topic_id
      t.integer :comment_id
      t.text :error_message
      t.timestamps

      t.index [:scheduled_date, :status]
    end
  end
end
