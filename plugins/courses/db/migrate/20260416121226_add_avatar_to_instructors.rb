class AddAvatarToInstructors < ActiveRecord::Migration[8.1]
  def change
    add_column :instructors, :avatar, :text
  end
end
