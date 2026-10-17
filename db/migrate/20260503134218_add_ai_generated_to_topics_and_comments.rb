class AddAiGeneratedToTopicsAndComments < ActiveRecord::Migration[8.1]
  def change
    add_column :topics, :ai_generated, :boolean, default: false, null: false
    add_column :comments, :ai_generated, :boolean, default: false, null: false
  end
end
