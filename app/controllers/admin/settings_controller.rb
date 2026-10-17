require "open-uri"

class Admin::SettingsController < Admin::DashboardController
  before_action :require_super_admin!
  skip_before_action :verify_authenticity_token, only: [:test_tms, :test_license]

  def index
    @settings = {
      license_key: SiteSetting.get("license_key", default: ""),
      license_file: license_file,
    }
    @license_verified = license_valid?
    @hardware_fingerprint = hardware_fingerprint
    return unless @license_verified

    @settings.merge!({
      site_locale: SiteSetting.get("site_locale", default: "zh-CN"),
      baidu_translate_appid: SiteSetting.get("baidu_translate_appid", default: ""),
      baidu_translate_key: SiteSetting.get("baidu_translate_key", default: ""),
      github_client_id: SiteSetting.get("github_client_id", default: ""),
      github_client_secret: SiteSetting.get("github_client_secret", default: ""),
      google_client_id: SiteSetting.get("google_client_id", default: ""),
      google_client_secret: SiteSetting.get("google_client_secret", default: ""),
      gitee_client_id: SiteSetting.get("gitee_client_id", default: ""),
      gitee_client_secret: SiteSetting.get("gitee_client_secret", default: ""),
      sendflare_api_token: SiteSetting.get("sendflare_api_token", default: ""),
      sendflare_from_email: SiteSetting.get("sendflare_from_email", default: ""),
      email_provider: SiteSetting.get("email_provider", default: "sendflare"),
      tencent_ses_secret_id: SiteSetting.get("tencent_ses_secret_id", default: ""),
      tencent_ses_secret_key: SiteSetting.get("tencent_ses_secret_key", default: ""),
      tencent_ses_from_email: SiteSetting.get("tencent_ses_from_email", default: ""),
      tencent_ses_region: SiteSetting.get("tencent_ses_region", default: "ap-guangzhou"),
      username_registration_enabled: SiteSetting.get("username_registration_enabled", default: "true"),
      email_registration_enabled: SiteSetting.get("email_registration_enabled", default: "true"),
      email_verification_enabled: SiteSetting.get("email_verification_enabled", default: "false"),
      invitation_code_enabled: SiteSetting.get("invitation_code_enabled", default: "false"),
      fake_users_count: SiteSetting.get("fake_users_count", default: "0"),
      fake_topics_count: SiteSetting.get("fake_topics_count", default: "0"),
      fake_comments_count: SiteSetting.get("fake_comments_count", default: "0"),
      invitation_code_hint: SiteSetting.get("invitation_code_hint", default: "注册需要邀请码，请向已有用户索取"),
      ai_api_key: SiteSetting.get("ai_api_key", default: ""),
      ai_base_url: SiteSetting.get("ai_base_url", default: ""),
      ai_model: SiteSetting.get("ai_model", default: ""),
      cps_ad_enabled: SiteSetting.get("cps_ad_enabled", default: "false"),
      auto_topic_enabled: SiteSetting.get("auto_topic_enabled", default: "false"),
      auto_topic_daily_count: SiteSetting.get("auto_topic_daily_count", default: "0"),
      auto_topic_mode: SiteSetting.get("auto_topic_mode", default: "draft"),
      auto_topic_time_start: SiteSetting.get("auto_topic_time_start", default: "8"),
      auto_topic_time_end: SiteSetting.get("auto_topic_time_end", default: "22"),
      auto_comment_enabled: SiteSetting.get("auto_comment_enabled", default: "false"),
      auto_comment_daily_count: SiteSetting.get("auto_comment_daily_count", default: "0"),
      auto_comment_time_start: SiteSetting.get("auto_comment_time_start", default: "8"),
      auto_comment_time_end: SiteSetting.get("auto_comment_time_end", default: "22"),
      ai_comment_prompt: SiteSetting.get("ai_comment_prompt", default: ""),
      ai_topic_prompt: SiteSetting.get("ai_topic_prompt", default: ""),
      ai_label_enabled: SiteSetting.get("ai_label_enabled", default: "false"),
      tencent_vod_app_id: SiteSetting.get("tencent_vod_app_id", default: ""),
      tencent_vod_secret_id: SiteSetting.get("tencent_vod_secret_id", default: ""),
      tencent_vod_secret_key: SiteSetting.get("tencent_vod_secret_key", default: ""),
      tencent_vod_psign_key: SiteSetting.get("tencent_vod_psign_key", default: ""),
      tencent_vod_sub_app_id: SiteSetting.get("tencent_vod_sub_app_id", default: ""),
      tencent_vod_license_url: SiteSetting.get("tencent_vod_license_url", default: ""),
      tencent_vod_adaptive_definition: SiteSetting.get("tencent_vod_adaptive_definition", default: ""),
      tencent_vod_adaptive_drm_type: SiteSetting.get("tencent_vod_adaptive_drm_type", default: "none"),
      tencent_vod_transcode_definitions: SiteSetting.get("tencent_vod_transcode_definitions", default: ""),
      tencent_vod_playback_domain: SiteSetting.get("tencent_vod_playback_domain", default: ""),
      tencent_cos_bucket: SiteSetting.get("tencent_cos_bucket", default: ""),
      image_storage: SiteSetting.get("image_storage", default: "local"),
      tencent_cos_region: SiteSetting.get("tencent_cos_region", default: ""),
      tencent_cos_secret_id: SiteSetting.get("tencent_cos_secret_id", default: ""),
      tencent_cos_secret_key: SiteSetting.get("tencent_cos_secret_key", default: ""),
      tencent_cos_custom_domain: SiteSetting.get("tencent_cos_custom_domain", default: ""),
      watermark_enabled: SiteSetting.get("watermark_enabled", default: "false"),
      watermark_text: SiteSetting.get("watermark_text", default: ""),
      watermark_position: SiteSetting.get("watermark_position", default: "bottom_right"),
      watermark_opacity: SiteSetting.get("watermark_opacity", default: "30"),
      watermark_font_size: SiteSetting.get("watermark_font_size", default: "24"),
      text_moderation_enabled: SiteSetting.get("text_moderation_enabled", default: "false"),
      tencent_tms_secret_id: SiteSetting.get("tencent_tms_secret_id", default: ""),
      tencent_tms_secret_key: SiteSetting.get("tencent_tms_secret_key", default: ""),
      tencent_tms_region: SiteSetting.get("tencent_tms_region", default: "ap-guangzhou"),
      tencent_tms_biz_type: SiteSetting.get("tencent_tms_biz_type", default: ""),
      tencent_tms_source_language: SiteSetting.get("tencent_tms_source_language", default: "zh"),
      tencent_captcha_enabled: SiteSetting.get("tencent_captcha_enabled", default: "false"),
      tencent_captcha_app_id: SiteSetting.get("tencent_captcha_app_id", default: ""),
      tencent_captcha_app_secret_key: SiteSetting.get("tencent_captcha_app_secret_key", default: ""),
      tencent_captcha_secret_id: SiteSetting.get("tencent_captcha_secret_id", default: ""),
      tencent_captcha_secret_key: SiteSetting.get("tencent_captcha_secret_key", default: "")
    })
    @local_images_count = Image.where(remote_url: [nil, ""]).select { |img| img.file.attached? }.size
  end

  def update
    settings = filter_protected_license_keys(params[:settings].to_unsafe_h)

    if request.content_type == "application/json"
      non_license = settings.except("license_key")
      if non_license.any? && !license_valid?
        render json: { error: t("admin.flash.m007") }, status: :forbidden
        return
      end
      settings.each do |key, value|
        SiteSetting.set(key, value)
      end
      render json: { ok: true }
    else
      non_license = settings.except("license_key")
      if non_license.any? && !license_valid?
        redirect_to admin_settings_path, alert: t("admin.flash.m007")
        return
      end
      settings.each do |key, value|
        SiteSetting.set(key, value)
      end
      redirect_to admin_settings_path, notice: t("admin.flash.m121")
    end
  end

  def migrate_images_to_cos
    unless TencentCosService.upload_to_cos?
      render json: { error: t("admin.flash.m126") }, status: :unprocessable_entity
      return
    end

    migrated = 0
    failed = 0
    url_map = {}

    # 1. 迁移 Image 模型中本地存储的图片到 COS
    local_images = Image.where(remote_url: [nil, ""])
    local_images.find_each do |image|
      next unless image.file.attached?

      blob = image.file.blob
      content_type = blob.content_type
      ext = case content_type
            when "image/png" then "png"
            when "image/gif" then "gif"
            when "image/webp" then "webp"
            else "jpg"
            end

      cos_path = "images/#{Time.current.strftime('%Y%m%d')}/#{SecureRandom.hex(8)}.#{ext}"
      url = TencentCosService.upload(cos_path, blob.download, content_type)

      if url
        image.update_column(:remote_url, url)
        url_map["/images/#{image.id}"] = url
        migrated += 1
      else
        failed += 1
      end
    rescue => e
      Rails.logger.error "[COS Migration] Image ##{image.id} failed: #{e.message}"
      failed += 1
    end

    # 2. 迁移讲师头像（base64/ActiveStorage -> COS）—— 讲师功能由 courses 插件提供
    instructor_scope = defined?(Instructor) ? Instructor.where.not(avatar: [nil, ""]).or(Instructor.joins(:avatar_file_attachment)) : Instructor.none rescue []
    instructor_scope.find_each do |inst|
      next if inst.avatar.present? && inst.avatar.start_with?("http")

      if inst.avatar_file.attached?
        blob = inst.avatar_file.blob
        cos_path = "avatars/#{Time.current.strftime('%Y%m%d')}/#{SecureRandom.hex(8)}.#{file_ext(blob.content_type)}"
        url = TencentCosService.upload(cos_path, blob.download, blob.content_type)
      elsif inst.avatar.present? && inst.avatar.start_with?("data:")
        match = inst.avatar.match(/^data:(image\/\w+);base64,(.+)$/)
        next unless match
        content_type = match[1]
        cos_path = "avatars/#{Time.current.strftime('%Y%m%d')}/#{SecureRandom.hex(8)}.#{file_ext(content_type)}"
        url = TencentCosService.upload(cos_path, Base64.decode64(match[2]), content_type)
      else
        next
      end

      if url
        inst.avatar_file.purge_later
        inst.update_column(:avatar, url)
        migrated += 1
      else
        failed += 1
      end
    rescue => e
      Rails.logger.error "[COS Migration] Instructor ##{inst.id} avatar failed: #{e.message}"
      failed += 1
    end

    # 3. 迁移用户头像（base64/ActiveStorage -> COS）
    User.where.not(avatar_data: [nil, ""]).or(User.joins(:avatar_file_attachment)).find_each do |u|
      next if u.avatar_data.present? && u.avatar_data.start_with?("http")

      if u.avatar_file.attached?
        blob = u.avatar_file.blob
        cos_path = "avatars/#{Time.current.strftime('%Y%m%d')}/#{SecureRandom.hex(8)}.#{file_ext(blob.content_type)}"
        url = TencentCosService.upload(cos_path, blob.download, blob.content_type)
      elsif u.avatar_data.present? && u.avatar_data.start_with?("data:")
        match = u.avatar_data.match(/^data:(image\/\w+);base64,(.+)$/)
        next unless match
        content_type = match[1]
        cos_path = "avatars/#{Time.current.strftime('%Y%m%d')}/#{SecureRandom.hex(8)}.#{file_ext(content_type)}"
        url = TencentCosService.upload(cos_path, Base64.decode64(match[2]), content_type)
      else
        next
      end

      if url
        u.avatar_file.purge_later
        u.update_column(:avatar_data, url)
        migrated += 1
      else
        failed += 1
      end
    rescue => e
      Rails.logger.error "[COS Migration] User ##{u.id} avatar failed: #{e.message}"
      failed += 1
    end

    # 4. 不再替换话题内容中的 /images/:id 代理链接为 COS 直链
    #    代理地址始终有效（通过 Image.remote_url 定位 COS 文件），
    #    保留代理地址才能让水印等功能正常工作。

    render json: { migrated: migrated, failed: failed, url_map_size: url_map.size }
  end

  def migrate_images_to_local
    unless TencentCosService.configured?
      render json: { error: "请先配置 COS 连接信息" }, status: :unprocessable_entity
      return
    end

    migrated = 0
    failed = 0
    url_map = {}

    # 1. 下载 COS 图片到本地 ActiveStorage
    cos_images = Image.where.not(remote_url: [nil, ""])
    cos_images.find_each do |image|
      cos_url = image.remote_url
      next unless cos_url.start_with?("http")

      begin
        io = URI.open(cos_url)
        ext = case io.content_type
              when "image/png" then "png"
              when "image/gif" then "gif"
              when "image/webp" then "webp"
              else "jpg"
              end
        filename = "cos_#{image.id}.#{ext}"
        image.file.attach(io: io, filename: filename, content_type: io.content_type)

        local_url = "/images/#{image.id}"
        url_map[cos_url] = local_url
        image.update_column(:remote_url, nil)
        migrated += 1
      rescue => e
        Rails.logger.error "[Local Migration] Image ##{image.id} failed: #{e.message}"
        failed += 1
      end
    end

    # 2. 下载 COS 讲师头像存为本地 ActiveStorage —— 讲师功能由 courses 插件提供
    local_instructor_scope = defined?(Instructor) ? Instructor.where.not(avatar: [nil, ""]) : Instructor.none rescue []
    local_instructor_scope.find_each do |inst|
      next unless inst.avatar.start_with?("http")

      begin
        io = URI.open(inst.avatar)
        ext = case io.content_type
              when "image/png" then "png"
              when "image/gif" then "gif"
              when "image/webp" then "webp"
              else "jpg"
              end
        filename = "avatar_#{inst.id}.#{ext}"
        inst.avatar_file.attach(io: io, filename: filename, content_type: io.content_type)
        inst.update_column(:avatar, nil)
        migrated += 1
      rescue => e
        Rails.logger.error "[Local Migration] Instructor ##{inst.id} avatar failed: #{e.message}"
        failed += 1
      end
    end

    # 3. 下载 COS 用户头像存为本地 ActiveStorage
    User.where.not(avatar_data: [nil, ""]).find_each do |u|
      next unless u.avatar_data.start_with?("http")

      begin
        io = URI.open(u.avatar_data)
        ext = case io.content_type
              when "image/png" then "png"
              when "image/gif" then "gif"
              when "image/webp" then "webp"
              else "jpg"
              end
        filename = "avatar_#{u.id}.#{ext}"
        u.avatar_file.attach(io: io, filename: filename, content_type: io.content_type)
        u.update_column(:avatar_data, nil)
        migrated += 1
      rescue => e
        Rails.logger.error "[Local Migration] User ##{u.id} avatar failed: #{e.message}"
        failed += 1
      end
    end

    # 4. 替换话题内容中的 COS 链接回本地链接
    if url_map.any?
      Topic.find_each do |topic|
        next if topic.content.blank?
        new_content = topic.content
        url_map.each do |cos_url, local_url|
          new_content = new_content.gsub(cos_url, local_url)
        end
        topic.update_column(:content, new_content) if new_content != topic.content
      end
    end

    render json: { migrated: migrated, failed: failed, url_map_size: url_map.size }
  end

  # 将话题内容中的 COS 直链替换为 /images/:id 代理地址，防止原图泄露
  def rewrite_image_urls_to_proxy
    replaced = 0

    # 构建所有 Image 的 remote_url -> /images/:id 映射
    url_map = {}
    Image.where.not(remote_url: [nil, ""]).find_each do |image|
      url_map[image.remote_url] = "/images/#{image.id}" if image.remote_url.start_with?("http")
    end

    return render json: { replaced: 0, message: t("admin.flash.m093") } if url_map.empty?

    Topic.find_each do |topic|
      next if topic.content.blank?
      new_content = topic.content.dup
      url_map.each do |cos_url, proxy_url|
        new_content = new_content.gsub(cos_url, proxy_url)
      end
      if new_content != topic.content
        topic.update_column(:content, new_content)
        replaced += 1
      end
    end

    # 同时处理评论中的图片链接
    Comment.find_each do |comment|
      next if comment.content.blank?
      new_content = comment.content.dup
      url_map.each do |cos_url, proxy_url|
        new_content = new_content.gsub(cos_url, proxy_url)
      end
      if new_content != comment.content
        comment.update_column(:content, new_content)
        replaced += 1
      end
    end

    render json: { replaced: replaced, url_map_size: url_map.size }
  end

  def test_tms
    text = params[:text].to_s.strip

    if text.blank?
      return render json: { error: t("admin.flash.m133") }, status: :unprocessable_entity
    end

    unless TextModerationService.enabled?
      secret_id = SiteSetting.get("tencent_tms_secret_id", default: "")
      secret_key = SiteSetting.get("tencent_tms_secret_key", default: "")
      if secret_id.blank? || secret_key.blank?
        return render json: { error: t("admin.flash.m127") }
      end
    end

    result = TextModerationService.check_simple(text)

    render json: result
  rescue => e
    render json: { error: t("admin.flash.m091", message: e.message) }
  end

  def test_license
    license_file = params[:license_file].to_s.strip

    if license_file.blank?
      render json: { success: false, error: t("admin.flash.m132") }
      return
    end

    result = activate_license(license_file_b64: license_file)

    if result[:success]
      render json: { success: true, data: result[:data] }
    else
      render json: { success: false, error: result[:error] }
    end
  end

  private

  # 许可证文件/公钥/快照仅由 activate_license 写入；
  # 授权码为空时保留已激活的授权码，避免保存设置时误清空
  def filter_protected_license_keys(settings)
    settings = settings.except("license_file", "license_public_key", "license_snapshot")
    settings = settings.except("license_key") if settings["license_key"].blank?
    settings
  end

  def file_ext(content_type)
    case content_type
    when "image/png" then "png"
    when "image/gif" then "gif"
    when "image/webp" then "webp"
    else "jpg"
    end
  end

  def require_super_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: t("admin.flash.m085")
    end
  end
end
