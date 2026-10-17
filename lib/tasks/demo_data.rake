# frozen_string_literal: true

namespace :demo_data do
  desc "导入论坛测试数据（用户/版块/主题/评论/点赞/收藏/关注/签到/投票等，幂等可重复执行）"
  task import: :environment do
    abort "仅管理员可在生产环境执行" if Rails.env.production? && ENV["FORCE"] != "true"

    stats = Admin::DemoDataService.import!
    puts "测试数据导入完成："
    stats.each { |key, count| puts format("  %-14s %d", key, count) }
  end

  desc "清空所有测试数据（以 demo_ 前缀标记的数据）"
  task clear: :environment do
    abort "仅管理员可在生产环境执行" if Rails.env.production? && ENV["FORCE"] != "true"

    result = Admin::DemoDataService.clear!
    puts "已清空测试数据：用户 #{result[:users]} 个、主题 #{result[:topics]} 篇"
  end
end
