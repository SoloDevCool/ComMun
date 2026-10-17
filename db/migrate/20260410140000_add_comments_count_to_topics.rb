class AddCommentsCountToTopics < ActiveRecord::Migration[8.1]
  def up
    unless column_exists?(:topics, :comments_count)
      add_column :topics, :comments_count, :integer, default: 0, null: false
    end
  end

  def down
    remove_column :topics, :comments_count if column_exists?(:topics, :comments_count)
  end
end
