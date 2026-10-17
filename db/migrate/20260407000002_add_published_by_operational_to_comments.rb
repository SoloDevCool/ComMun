class AddPublishedByOperationalToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :published_by_operational, :boolean, default: false, null: false
    add_index :comments, :published_by_operational
  end
end
