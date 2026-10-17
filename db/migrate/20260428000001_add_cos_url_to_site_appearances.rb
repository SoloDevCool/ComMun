class AddCosUrlToSiteAppearances < ActiveRecord::Migration[8.1]
  def change
    add_column :site_appearances, :logo_url, :string
    add_column :site_appearances, :favicon_url, :string
  end
end
