class CreateThemes < ActiveRecord::Migration[8.1]
  def change
    create_table :themes do |t|
      t.string :name, null: false
      t.string :identifier, null: false
      t.string :version, null: false
      t.text :description
      t.string :author
      t.string :homepage
      t.jsonb :metadata, default: {}
      t.string :preview_color
      t.string :status, default: "installed", null: false
      t.string :screenshot_url
      t.string :custom_css_url
      t.string :styles_url
      t.string :dark_styles_url
      t.jsonb :assets_urls, default: {}
      t.timestamps
    end

    add_index :themes, :identifier, unique: true
    add_index :themes, :status
  end
end
