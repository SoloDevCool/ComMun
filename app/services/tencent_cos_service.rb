require "digest"
require "openssl"
require "net/http"
require "uri"

class TencentCosService
  COS_HOST_TEMPLATE = "cos.%{region}.myqcloud.com"
  MAX_FILE_SIZE = 5 * 1024 * 1024 # 5MB

  def self.configured?
    bucket.present? && region.present? && secret_id.present? && secret_key.present?
  end

  # 判断是否启用 COS 存储（配置完整且设置中选择了 COS）
  def self.upload_to_cos?
    SiteSetting.get("image_storage", default: "local") == "cos" && configured?
  end

  # 上传文件到 COS，返回公开访问 URL
  # path: 存储路径，如 "avatars/20260416/abc123.jpg"
  def self.upload(path, file_data, content_type = "image/jpeg")
    return nil unless configured?

    bucket_name = bucket
    region_name = region
    host = format(COS_HOST_TEMPLATE, region: region_name)
    bucket_host = "#{bucket_name}.#{host}"
    object_url = "https://#{bucket_host}/#{path}"

    uri = URI(object_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Put.new(uri)
    request["Content-Type"] = content_type
    request["Host"] = bucket_host
    request.body = file_data

    authorize_request(request, :put, path, bucket_host)

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      # 返回公开访问 URL，优先使用自定义域名
      if custom_domain.present?
        "https://#{custom_domain}/#{path}"
      else
        object_url
      end
    else
      Rails.logger.error "[COS] Upload failed: #{response.code} #{response.body}"
      nil
    end
  end

  # 删除 COS 上的文件
  def self.delete(path)
    return false unless configured?

    bucket_name = bucket
    region_name = region
    host = format(COS_HOST_TEMPLATE, region: region_name)
    bucket_host = "#{bucket_name}.#{host}"
    object_url = "https://#{bucket_host}/#{path}"

    uri = URI(object_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 15

    request = Net::HTTP::Delete.new(uri)
    request["Host"] = bucket_host

    authorize_request(request, :delete, path, bucket_host)

    response = http.request(request)
    response.is_a?(Net::HTTPSuccess)
  end

  # 将任意图片 URL 转换为 COS 默认域名 URL
  # 用于 COS 数据处理接口（如水印），这些接口要求使用 COS 默认域名
  def self.cos_domain_url(url)
    return nil unless url.present? && configured?

    uri = URI.parse(url)
    path = uri.path.sub(%r{\A/}, "")
    return nil if path.blank?

    host = format(COS_HOST_TEMPLATE, region: region)
    "https://#{bucket}.#{host}/#{path}"
  rescue URI::InvalidURIError
    nil
  end

  private

  def self.bucket
    SiteSetting.get("tencent_cos_bucket", default: "").strip
  end

  def self.region
    SiteSetting.get("tencent_cos_region", default: "").strip
  end

  def self.secret_id
    SiteSetting.get("tencent_cos_secret_id", default: "").strip
  end

  def self.secret_key
    SiteSetting.get("tencent_cos_secret_key", default: "").strip
  end

  def self.custom_domain
    domain = SiteSetting.get("tencent_cos_custom_domain", default: "")
    domain = domain.sub(%r{\Ahttps?://}, "").sub(%r{/+\z}, "") if domain.present?
    domain.presence
  end

  def self.authorize_request(request, http_method, path, host)
    start_time = Time.current.utc
    expire_seconds = 3600
    key_time = "#{start_time.to_i};#{start_time.to_i + expire_seconds}"

    # SignKey = HMAC-SHA1(SecretKey, KeyTime) — 使用十六进制字符串
    sign_key = OpenSSL::HMAC.hexdigest("SHA1", secret_key, key_time)

    # HttpString = HttpMethod\nUriPathname\nHttpParameters\nHttpHeaders\n
    http_string = "#{http_method.to_s.downcase}\n/#{path}\n\n\n"
    http_string_sha1 = Digest::SHA1.hexdigest(http_string)

    # StringToSign = "sha1\n{KeyTime}\n{SHA1(HttpString)}\n"
    string_to_sign = "sha1\n#{key_time}\n#{http_string_sha1}\n"

    # Signature = HMAC-SHA1(SignKey, StringToSign)
    signature = OpenSSL::HMAC.hexdigest("SHA1", sign_key, string_to_sign)

    Rails.logger.debug "[COS] Sign debug: key_time=#{key_time}, http_string_sha1=#{http_string_sha1}, string_to_sign=#{string_to_sign.dump}, signature=#{signature}, secret_key_length=#{secret_key.length}, secret_id=#{secret_id}"

    # Authorization: q-sign-algorithm=sha1&q-ak=SecretId&q-sign-time=KeyTime&q-key-time=KeyTime&q-header-list=&q-url-param-list=&q-signature=Signature
    request["Authorization"] = [
      "q-sign-algorithm=sha1",
      "q-ak=#{secret_id}",
      "q-sign-time=#{key_time}",
      "q-key-time=#{key_time}",
      "q-header-list=",
      "q-url-param-list=",
      "q-signature=#{signature}"
    ].join("&")
  end
end
