class SiteAppearance < ApplicationRecord
  has_one_attached :logo
  has_one_attached :favicon

  validate :acceptable_logo
  validate :acceptable_favicon
  validate :acceptable_logo_display_mode

  after_save :sync_logo_to_cos, if: :logo_changed?
  after_save :sync_favicon_to_cos, if: :favicon_changed?

  ALLOWED_LOGO_TYPES = %w[image/png image/jpeg image/gif image/webp image/svg+xml].freeze
  ALLOWED_FAVICON_TYPES = %w[image/png image/jpeg image/gif image/webp image/svg+xml image/x-icon].freeze
  LOGO_DISPLAY_MODES = %w[text logo icon_logo].freeze

  def self.instance
    first || create!
  end

  def remove_logo_from_cos!
    return if logo_url.blank?
    TencentCosService.delete(cos_path_from_url(logo_url))
    update_column(:logo_url, nil)
  end

  def remove_favicon_from_cos!
    return if favicon_url.blank?
    TencentCosService.delete(cos_path_from_url(favicon_url))
    update_column(:favicon_url, nil)
  end

  private

  def logo_changed?
    saved_change_to_attribute?(:logo_url) || (logo.attached? && !logo_url.present?)
  end

  def favicon_changed?
    saved_change_to_attribute?(:favicon_url) || (favicon.attached? && !favicon_url.present?)
  end

  def sync_logo_to_cos
    return unless logo.attached?
    return unless TencentCosService.configured?

    begin
      path = "appearance/logo#{file_ext(logo)}"
      io = logo.download
      cos_url = TencentCosService.upload(path, io, logo.content_type)
      io.close

      update_column(:logo_url, cos_url) if cos_url
    rescue ActiveStorage::FileNotFoundError, Errno::ENOENT
      Rails.logger.warn("[SiteAppearance] logo 文件未找到，跳过 COS 同步")
    end
  end

  def sync_favicon_to_cos
    return unless favicon.attached?
    return unless TencentCosService.configured?

    begin
      path = "appearance/favicon#{file_ext(favicon)}"
      io = favicon.download
      cos_url = TencentCosService.upload(path, io, favicon.content_type)
      io.close

      update_column(:favicon_url, cos_url) if cos_url
    rescue ActiveStorage::FileNotFoundError, Errno::ENOENT
      Rails.logger.warn("[SiteAppearance] favicon 文件未找到，跳过 COS 同步")
    end
  end

  def file_ext(attachment)
    ext = case attachment.content_type
          when "image/png" then ".png"
          when "image/jpeg" then ".jpg"
          when "image/gif" then ".gif"
          when "image/webp" then ".webp"
          when "image/svg+xml" then ".svg"
          when "image/x-icon" then ".ico"
          else ".png"
          end
    # 加时间戳避免浏览器缓存
    "#{ext}?t=#{Time.current.to_i}"
  end

  def cos_path_from_url(url)
    uri = URI.parse(url)
    uri.path.sub(%r{\A/}, "").split("?").first
  rescue URI::InvalidURIError
    url
  end

  def acceptable_logo
    validate_attachment(:logo, ALLOWED_LOGO_TYPES, 2.megabytes, "Logo")
  end

  def acceptable_favicon
    validate_attachment(:favicon, ALLOWED_FAVICON_TYPES, 1.megabyte, "图标")
  end

  def validate_attachment(attachment, allowed_types, max_size, label)
    return unless send(attachment).attached?

    if send(attachment).blob.byte_size > max_size
      errors.add(attachment, "#{label}文件大小不能超过 #{(max_size / 1.megabyte).to_i}MB")
    end

    unless allowed_types.include?(send(attachment).blob.content_type)
      errors.add(attachment, "#{label}格式不支持")
    end
  end

  def acceptable_logo_display_mode
    unless LOGO_DISPLAY_MODES.include?(logo_display_mode)
      errors.add(:logo_display_mode, "不合法的展示方式")
    end
  end
end
