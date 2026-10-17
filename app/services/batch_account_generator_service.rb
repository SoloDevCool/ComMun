require "net/http"
require "json"
require "open-uri"

AVATAR_API_URL = "https://v2.xxapi.cn/api/head?return=json"

class BatchAccountGeneratorService
  AVATAR_METHODS = %w[api multiavatar].freeze

  attr_reader :count, :email_domain, :password, :role, :results

  def initialize(count:, email_domain:, password:, role: "user")
    @count = count.to_i
    @email_domain = email_domain.to_s.strip
    @password = password.to_s.strip
    @role = role.to_s.strip
    @results = []
  end

  def call
    return { success: false, message: "数量需在 1~100 之间", results: [] } unless count.between?(1, 100)
    return { success: false, message: "邮箱域名不能为空", results: [] } if email_domain.blank?
    return { success: false, message: "密码不能为空，且至少 6 个字符", results: [] } if password.length < 6
    return { success: false, message: "角色无效", results: [] } unless Role.exists_with_key?(role)

    generated = 0
    generated_usernames = User.pluck(:username).index_with(&:itself)

    count.times do
      username = generate_unique_username(generated_usernames)
      email = "#{username}@#{email_domain}"

      user = User.new(
        username: username,
        email: email,
        password: password,
        password_confirmation: password,
        role: role,
        is_operational: true,
        plaintext_password: password
      )

      if user.save
        assign_random_avatar(user)
        generated_usernames[username] = true
        generated += 1
        results << { username: username, email: email, password: password, success: true }
      else
        results << { username: username, email: email, password: password, success: false, errors: user.errors.full_messages.join(", ") }
      end
    end

    { success: true, message: "成功生成 #{generated}/#{count} 个账号", results: results }
  end

  # 当前头像生成方式
  def self.avatar_method
    SiteSetting.get("avatar_method", default: "multiavatar")
  end

  # 头像生成方式可选项（用于视图渲染）
  def self.avatar_method_options
    AVATAR_METHODS.map { |m| [avatar_method_label(m), m] }
  end

  def self.avatar_method_label(method)
    case method
    when "multiavatar" then "Multiavatar（本地生成）"
    else "随机图片 API（远程获取）"
    end
  end

  # 为单个用户生成头像（根据当前配置自动选择生成方式）
  def self.generate_avatar_for(user)
    case avatar_method
    when "multiavatar"
      MultiavatarService.generate_avatar_for(user)
    else
      generate_avatar_via_api(user)
    end
  end

  # 为单个用户按指定方式生成头像
  def self.generate_avatar_for_with_method(user, method)
    case method
    when "multiavatar"
      MultiavatarService.generate_avatar_for(user)
    else
      generate_avatar_via_api(user)
    end
  end

  def self.generate_avatars_for_missing
    users = User.operational.where(avatar_data: [nil, ""])
    users = users.or(User.operational.joins(:avatar_file_attachment)) if users.count.zero?
    generated = 0
    users.find_each do |user|
      if generate_avatar_for(user)
        generated += 1
      end
    end
    generated
  end

  private

  def assign_random_avatar(user)
    self.class.generate_avatar_for(user)
  rescue StandardError
    nil
  end

  # 通过第三方 API 生成头像（原始方式）
  def self.generate_avatar_via_api(user)
    uri = URI(AVATAR_API_URL)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)
    image_url = data.dig("data")
    return nil unless image_url.present?

    io = URI.open(URI(image_url), read_timeout: 10, open_timeout: 5)
    content_type = io.meta["content-type"] || "image/jpeg"

    if TencentCosService.upload_to_cos?
      ext = case content_type
            when "image/png" then "png"
            when "image/gif" then "gif"
            when "image/webp" then "webp"
            else "jpg"
            end
      cos_path = "avatars/#{Time.current.strftime('%Y%m%d')}/#{SecureRandom.hex(8)}.#{ext}"
      url = TencentCosService.upload(cos_path, io.read, content_type)
      user.update_column(:avatar_data, url) if url
    else
      user.avatar_file.attach(io: io, filename: "avatar_#{user.id}.jpg", content_type: content_type)
      user.update_column(:avatar_data, nil)
    end
  rescue StandardError
    nil
  end

  private_class_method :generate_avatar_via_api

  def generate_unique_username(existing)
    20.times do
      username = Faker::Internet.username(specifier: 6..10, separators: ["_"])
      username = username.gsub(/[^a-zA-Z0-9_]/, "")[0, 20]

      next if username.length < 2
      next if existing.key?(username.downcase)

      return username
    end

    # Fallback: random alphanumeric
    SecureRandom.alphanumeric(8).downcase
  end
end
