require "base64"
require "uri"

class ImageWatermarkService
  # COS 水印位置映射：我们的设置名 → COS gravity 参数
  POSITION_MAP = {
    "top_left"     => "northwest",
    "top_center"   => "north",
    "top_right"    => "northeast",
    "center"       => "center",
    "bottom_left"  => "southwest",
    "bottom_center" => "south",
    "bottom_right" => "southeast"
  }.freeze

  def self.enabled?
    SiteSetting.get("watermark_enabled", default: "false") == "true"
  end

  # 水印配置变更时缓存失效用的 key
  def self.cache_key
    [
      SiteSetting.get("watermark_text", default: ""),
      SiteSetting.get("watermark_position", default: "bottom_right"),
      SiteSetting.get("watermark_opacity", default: "30"),
      SiteSetting.get("watermark_font_size", default: "24")
    ].join("|")
  end

  # 判断是否可以使用 COS 水印（图片在 COS 上且 COS 配置完整）
  def self.cos_watermark_available?(image)
    image.remote_url? && TencentCosService.configured?
  end

  # 生成 COS 带水印参数的 URL
  def self.watermark_url(image)
    return nil unless cos_watermark_available?(image)

    cos_url = TencentCosService.cos_domain_url(image.remote_url)
    return nil unless cos_url

    text = SiteSetting.get("watermark_text", default: "").strip
    return nil if text.blank?

    opacity  = SiteSetting.get("watermark_opacity", default: "30").to_i.clamp(1, 100)
    position = POSITION_MAP[SiteSetting.get("watermark_position", default: "bottom_right")] || "southeast"
    font_size = SiteSetting.get("watermark_font_size", default: "24").to_i.clamp(10, 200)

    encoded_text = url_safe_base64(text.encode("UTF-8"))
    fill_color = SiteSetting.get("watermark_fill_color", default: "#888888")
    encoded_fill = url_safe_base64(fill_color)

    "#{cos_url}?watermark/2/text/#{encoded_text}/fill/#{encoded_fill}/fontsize/#{font_size}/dissolve/#{opacity}/gravity/#{position}"
  end

  # 从 Image 对象获取原图二进制数据，返回 [data, content_type]
  def self.fetch_original(image)
    if image.remote_url?
      uri = URI.parse(image.remote_url)
      io = URI.open(uri, read_timeout: 15, open_timeout: 5)
      content_type = io.meta["content-type"].to_s.split(";").first.strip
      content_type = "image/jpeg" if content_type.blank?
      [io.read, content_type]
    elsif image.file.attached?
      blob = image.file.blob
      [blob.download, blob.content_type]
    end
  rescue => e
    Rails.logger.error "[Watermark] fetch_original failed for Image ##{image&.id}: #{e.class} #{e.message}"
    nil
  end

  private

  # URL 安全的 Base64 编码（去除尾部的 =）
  def self.url_safe_base64(str)
    Base64.urlsafe_encode64(str).delete("=")
  end
end
