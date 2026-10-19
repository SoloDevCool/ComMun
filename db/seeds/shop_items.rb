# Seed data for Shop Items
# Run: rails db:seed:replant or rails runner db/seeds/shop_items.rb

ShopItem.find_or_create_by!(name: "ComMun 开源版 License") do |item|
  item.description = "获得 ComMun 开源版授权许可，解锁系统完整功能。License 将自动配置到系统设置中。"
  item.item_type = "license"
  item.price = 100
  item.icon = "bi-shield-lock"
  item.active = true
  item.stock = -1
  item.sort_order = 0
  item.metadata = { "plan" => "free" }
end

puts "Shop items seeded successfully!"
