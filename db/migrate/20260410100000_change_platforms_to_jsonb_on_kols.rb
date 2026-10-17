class ChangePlatformsToJsonbOnKols < ActiveRecord::Migration[8.1]
  def up
    change_column :kols, :platforms, :jsonb, default: [], using: 'platforms::jsonb'
  end

  def down
    change_column :kols, :platforms, :json, default: []
  end
end
