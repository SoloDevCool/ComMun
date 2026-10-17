class CreateTopicEnergyUnlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :topic_energy_unlocks do |t|
      t.bigint :topic_id, null: false
      t.bigint :user_id, null: false
      t.integer :block_index, null: false
      t.integer :energy_cost, null: false
      t.datetime :created_at, null: false

      t.index [:topic_id, :user_id, :block_index], unique: true, name: "index_topic_energy_unlocks_on_topic_user_block"
      t.index [:user_id], name: "index_topic_energy_unlocks_on_user_id"
    end
  end
end
