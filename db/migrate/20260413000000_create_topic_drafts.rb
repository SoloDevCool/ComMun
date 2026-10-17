class CreateTopicDrafts < ActiveRecord::Migration[7.1]
  def change
    create_table :topic_drafts do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.references :node, null: false, foreign_key: true
      t.boolean :is_repost, default: false
      t.string :source_url
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :topic_drafts, [:user_id, :updated_at]
  end
end
