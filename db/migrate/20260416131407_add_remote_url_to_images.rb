class AddRemoteUrlToImages < ActiveRecord::Migration[8.1]
  def change
    add_column :images, :remote_url, :string
  end
end
