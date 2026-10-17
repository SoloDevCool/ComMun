# frozen_string_literal: true

namespace :admin do
  desc "创建默认管理员账号"
  task create: :environment do
    require "io/console"

    puts "=" * 50
    puts "  创建默认管理员账号"
    puts "=" * 50

    # 从环境变量读取或交互式输入
    email = ENV["ADMIN_EMAIL"]
    username = ENV["ADMIN_USERNAME"]
    password = ENV["ADMIN_PASSWORD"]

    if email.blank? || password.blank?
      puts
      puts "提示: 也可以通过环境变量指定, 例如:"
      puts "  ADMIN_EMAIL=admin@example.com ADMIN_USERNAME=admin ADMIN_PASSWORD=xxx rails admin:create"
      puts
    end

    email    = prompt_input("邮箱", email, "admin@example.com")
    username = prompt_input("用户名", username, "admin")

    if password.blank?
      password = prompt_password("密码")
      confirm  = prompt_password("确认密码")
      if password != confirm
        abort "\n[错误] 两次输入的密码不一致，已退出。"
      end
    end

    if password.length < 6
      abort "\n[错误] 密码长度不能少于 6 位。"
    end

    create_admin!(email, username, password)
  end

  desc "创建默认管理员账号（非交互模式，必须通过环境变量指定）"
  task create_silent: :environment do
    email    = ENV["ADMIN_EMAIL"]
    username = ENV["ADMIN_USERNAME"]
    password = ENV["ADMIN_PASSWORD"]

    missing = []
    missing << "ADMIN_EMAIL"    if email.blank?
    missing << "ADMIN_USERNAME" if username.blank?
    missing << "ADMIN_PASSWORD" if password.blank?

    unless missing.empty?
      abort "[错误] 非交互模式需要设置环境变量: #{missing.join(", ")}"
    end

    create_admin!(email.strip, username.strip, password.strip)
  end

  private

  def self.prompt_input(label, default_value, fallback)
    value = default_value
    if value.blank?
      print "  请输入#{label} [默认: #{fallback}]: "
      value = $stdin.gets&.strip
      value = value.blank? ? fallback : value
    else
      puts "  #{label}: #{value}"
    end
    value
  end

  def self.prompt_password(label)
    print "  请输入#{label}: "
    value = $stdin.noecho(&:gets)&.strip
    puts
    value
  end

  def self.create_admin!(email, username, password)
    if User.exists?(email: email)
      user = User.find_by!(email: email)
      if user.admin?
        puts "\n[跳过] 邮箱 #{email} 已是管理员账号，无需重复创建。"
        return
      else
        user.update!(role: :admin, password: password)
        puts "\n[完成] 已将 #{email} 的角色升级为管理员。"
        return
      end
    end

    user = User.create!(
      email:    email,
      username: username,
      password: password,
      role:     :admin
    )

    puts "\n[完成] 管理员账号创建成功！"
    puts "  邮箱:   #{user.email}"
    puts "  用户名: #{user.username}"
    puts "  角色:   #{user.role}"
    puts
  end
end
