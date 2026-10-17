class AddModerationFieldsToTopicsAndComments < ActiveRecord::Migration[8.1]
  def change
    add_column :topics, :moderation_status, :string, default: "pass", null: false
    add_column :topics, :moderation_label, :string
    add_column :topics, :moderation_sub_label, :string
    add_column :topics, :moderation_score, :integer
    add_column :topics, :moderation_keywords, :string, array: true, default: []
    add_column :topics, :moderation_checked_at, :datetime

    add_column :comments, :moderation_status, :string, default: "pass", null: false
    add_column :comments, :moderation_label, :string
    add_column :comments, :moderation_sub_label, :string
    add_column :comments, :moderation_score, :integer
    add_column :comments, :moderation_keywords, :string, array: true, default: []
    add_column :comments, :moderation_checked_at, :datetime

    add_index :topics, :moderation_status
    add_index :comments, :moderation_status
  end
end
