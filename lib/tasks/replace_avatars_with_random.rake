# 将所有用户头像替换为随机图片 API（远程获取）的头像
#
# 用法:
#   rails avatars:replace_with_random                # 全部用户
#   rails avatars:replace_with_random FORCE=false    # 仅替换无头像的用户（预览模式不会执行）
#
# 说明:
# - 使用 https://i.pravatar.cc 随机头像 API（内置 70 张真实人像头像，img=1..70）
# - 同时清除 ActiveStorage 附件 avatar_file（优先级高于 avatar_data）
# - avatar_data 直接存储远程 URL，前端 <img src> 可直接使用
namespace :avatars do
  desc "将所有用户头像替换为随机图片 API（远程获取）"
  task replace_with_random: :environment do
    require "open-uri"

    api_base = ENV.fetch("RANDOM_AVATAR_API", "https://i.pravatar.cc/150")
    max_index = 70 # pravatar 支持的 img 参数范围 1..70

    total = User.count
    purged = 0
    updated = 0
    failed = 0

    puts "共 #{total} 个用户，开始替换头像..."

    User.find_each do |user|
      begin
        # 优先级：avatar_file > avatar_data，必须先清掉附件替换才生效
        if user.avatar_file.attached?
          user.avatar_file.purge
          purged += 1
        end

        # avatar_data 存远程 URL 即可，无需下载图片
        user.update_column(:avatar_data, "#{api_base}?img=#{rand(1..max_index)}")
        updated += 1
        print "."
      rescue StandardError => e
        failed += 1
        puts "\n[失败] 用户 #{user.id} (#{user.username}): #{e.message}"
      end
    end

    puts ""
    puts "完成: 更新 #{updated}/#{total}，清除附件 #{purged}，失败 #{failed}"
  end
end
