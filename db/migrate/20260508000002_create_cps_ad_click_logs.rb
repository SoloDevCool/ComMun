class CreateCpsAdClickLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :cps_ad_click_logs do |t|
      t.references :cps_ad, null: false, foreign_key: true, index: false
      t.references :user, foreign_key: true, index: false
      t.string :ip_address, null: false
      t.string :country, default: ""
      t.string :province, default: ""
      t.string :city, default: ""
      t.string :isp, default: ""
      t.string :user_agent, default: ""
      t.string :browser, default: ""
      t.string :os, default: ""
      t.string :referer, default: ""
      t.timestamps
    end

    add_index :cps_ad_click_logs, :cps_ad_id
    add_index :cps_ad_click_logs, :user_id
    add_index :cps_ad_click_logs, :ip_address
    add_index :cps_ad_click_logs, :created_at
  end
end
