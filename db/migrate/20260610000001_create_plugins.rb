class CreatePlugins < ActiveRecord::Migration[8.1]
  def change
    create_table :plugins do |t|
      t.string :name, null: false
      t.string :identifier, null: false
      t.string :version, null: false, default: "1.0.0"
      t.text :description
      t.string :author
      t.string :homepage
      t.string :status, null: false, default: "uninstalled"
      t.jsonb :config, default: {}
      t.jsonb :hooks, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :plugins, :identifier, unique: true
    add_index :plugins, :status
  end
end
