class CreateUserLoginLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :user_login_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address, null: false
      t.string :country, default: ""
      t.string :province, default: ""
      t.string :city, default: ""
      t.string :isp, default: ""
      t.string :user_agent
      t.string :browser
      t.string :os

      t.timestamps
    end

    add_index :user_login_logs, :ip_address
    add_index :user_login_logs, :created_at
  end
end
