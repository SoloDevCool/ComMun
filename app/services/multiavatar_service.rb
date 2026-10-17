require "mini_racer"

class MultiavatarService
  MULTIavatar_JS_PATH = Rails.root.join("vendor", "javascript", "multiavatar.js")

  class << self
    # 根据字符串生成 Multiavatar SVG
    def generate_svg(string, sans_env: false)
      context = js_context
      context.eval("multiavatar('#{escape_js(string)}', #{sans_env})")
    rescue StandardError => e
      Rails.logger.error "[MultiavatarService] SVG 生成失败: #{e.message}"
      nil
    end

    # 为用户生成头像并保存（接口与 BatchAccountGeneratorService.generate_avatar_for 一致）
    def generate_avatar_for(user)
      svg_string = generate_svg(user.username || user.id.to_s)
      return nil unless svg_string&.present?

      svg_bytes = svg_string.b
      data_uri = "data:image/svg+xml;base64,#{Base64.strict_encode64(svg_bytes)}"
      user.update_column(:avatar_data, data_uri)
    rescue StandardError => e
      Rails.logger.error "[MultiavatarService] 为用户 #{user.id} 生成头像失败: #{e.message}"
      nil
    end

    # 为所有缺失头像的运营账号批量生成
    def generate_avatars_for_missing
      users = User.operational.where(avatar_data: [nil, ""])
      users = users.or(User.operational.joins(:avatar_file_attachment)) if users.count.zero?
      generated = 0
      users.find_each do |user|
        generated += 1 if generate_avatar_for(user)
      end
      generated
    end

    private

    # 缓存 JS 上下文（Multiavatar 库较大，避免重复解析）
    def js_context
      Thread.current[:multiavatar_ctx] ||= begin
        ctx = MiniRacer::Context.new
        ctx.eval(File.read(MULTIavatar_JS_PATH))
        ctx
      end
    end

    def escape_js(string)
      string.to_s.gsub('\\', '\\\\\\\\').gsub("'", "\\\\'").gsub("\n", '\\n').gsub("\r", '\\r')
    end
  end
end
