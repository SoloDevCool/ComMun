class AddUrlToKols < ActiveRecord::Migration[8.1]
  def change
    add_column :kols, :url, :string
  end
end
