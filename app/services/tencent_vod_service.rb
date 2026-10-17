require "json"
require "base64"
require "openssl"
require "uri"
require "net/http"
require "digest"

class TencentVodService
  UPLOAD_SIGNATURE_EXPIRE = 86400 * 2
  PSIGN_EXPIRE_SECONDS = 7200  # 2小时，缩短有效期减少签名被盗用风险
  VOD_API_HOST = "vod.tencentcloudapi.com"
  VOD_API_ENDPOINT = "https://#{VOD_API_HOST}"
  VOD_SERVICE = "vod"
  VOD_API_VERSION = "2020-08-17"

  # 生成客户端上传签名（HMAC-SHA1 + Base64）
  def self.generate_upload_signature(secret_id, secret_key)
    timestamp = Time.current.to_i
    expire_time = timestamp + UPLOAD_SIGNATURE_EXPIRE
    random = rand(10**6)

    original = "secretId=#{ERB::Util.url_encode(secret_id)}" \
               "&currentTimeStamp=#{timestamp}" \
               "&expireTime=#{expire_time}" \
               "&random=#{random}"

    # 如果配置了子应用 ID，加入签名
    sub_app_id = SiteSetting.get("tencent_vod_sub_app_id", default: "")
    if sub_app_id.present?
      original += "&vodSubAppId=#{sub_app_id}"
    end

    hmac = OpenSSL::HMAC.digest("SHA1", secret_key, original)
    Base64.strict_encode64(hmac + original.b)
  end

  # 生成播放器签名（psign，JWT 格式：Header.Payload.Signature）
  def self.generate_psign(file_id, psign_key)
    app_id = SiteSetting.get("tencent_vod_app_id", default: "").to_s
    sub_app_id = SiteSetting.get("tencent_vod_sub_app_id", default: "")

    # 如果配置了子应用，appId 使用子应用 ID（让 getplayinfo 路由到子应用）
    effective_app_id = sub_app_id.present? ? sub_app_id.to_i : app_id.to_i

    header = {
      "alg" => "HS256",
      "typ" => "JWT"
    }

    # 构建 contentInfo
    # 优先级：自适应码流 > 转码(Transcode) > 原始(Original)
    # 自适应码流分两种：
    #   RawAdaptive: 未加密自适应码流，配合 rawAdaptiveDefinition
    #   ProtectedAdaptive: 加密自适应码流(SimpleAES/Widevine/FairPlay)，配合 drmAdaptiveInfo
    # Transcode: 指定转码模板，配合 transcodeDefinition
    # Original: 直接播放原始上传文件
    adaptive_def = SiteSetting.get("tencent_vod_adaptive_definition", default: "")
    adaptive_drm_type = SiteSetting.get("tencent_vod_adaptive_drm_type", default: "none")
    transcode_def = SiteSetting.get("tencent_vod_transcode_definitions", default: "")

    if adaptive_def.present?
      adaptive_def_int = adaptive_def.strip.to_i

      if adaptive_drm_type == "none"
        # 未加密自适应码流
        content_info = {
          "audioVideoType" => "RawAdaptive",
          "rawAdaptiveDefinition" => adaptive_def_int
        }
      else
        # 加密自适应码流
        drm_adaptive_info = build_drm_adaptive_info(adaptive_drm_type, adaptive_def_int)
        content_info = {
          "audioVideoType" => "ProtectedAdaptive",
          "drmAdaptiveInfo" => drm_adaptive_info
        }
      end
    elsif transcode_def.present?
      content_info = {
        "audioVideoType" => "Transcode",
        "transcodeDefinition" => transcode_def.strip.to_i
      }
    else
      content_info = {
        "audioVideoType" => "Original"
      }
    end

    # 防盗链播放域名白名单
    playback_domain = SiteSetting.get("tencent_vod_playback_domain", default: "")
    if playback_domain.present?
      content_info["currentPlaybackUrl"] = playback_domain
    end

    payload = {
      "appId" => effective_app_id,
      "fileId" => file_id,
      "contentInfo" => content_info,
      "currentTimeStamp" => Time.current.to_i,
      "expireTimeStamp" => Time.current.to_i + PSIGN_EXPIRE_SECONDS
    }

    encoded_header = base64url_encode(JSON.generate(header))
    encoded_payload = base64url_encode(JSON.generate(payload))

    signing_input = "#{encoded_header}.#{encoded_payload}"
    hmac = OpenSSL::HMAC.digest("SHA256", psign_key, signing_input)
    encoded_signature = base64url_encode(hmac)

    "#{signing_input}.#{encoded_signature}"
  end

  # 通过服务端 API 获取视频播放地址（支持子应用）
  def self.get_play_url(file_id)
    secret_id = SiteSetting.get("tencent_vod_secret_id", default: "")
    secret_key = SiteSetting.get("tencent_vod_secret_key", default: "")
    sub_app_id = SiteSetting.get("tencent_vod_sub_app_id", default: "")

    if secret_id.blank? || secret_key.blank?
      raise "未配置 SecretId/SecretKey"
    end

    payload = {
      "FileIds" => [file_id]
    }
    if sub_app_id.present?
      payload["SubAppId"] = sub_app_id.to_i
    end

    response = call_api("DescribeMediaInfos", payload, secret_id, secret_key)
    response
  end

  # 删除媒体文件（支持子应用）
  def self.delete_media(file_id)
    secret_id = SiteSetting.get("tencent_vod_secret_id", default: "")
    secret_key = SiteSetting.get("tencent_vod_secret_key", default: "")
    sub_app_id = SiteSetting.get("tencent_vod_sub_app_id", default: "")

    if secret_id.blank? || secret_key.blank?
      raise "未配置 SecretId/SecretKey"
    end

    payload = {
      "FileId" => file_id
    }
    if sub_app_id.present?
      payload["SubAppId"] = sub_app_id.to_i
    end

    call_api("DeleteMedia", payload, secret_id, secret_key, "2018-07-17")
  end

  # 调用腾讯云 API v3
  def self.call_api(action, payload, secret_id, secret_key, version = VOD_API_VERSION)
    timestamp = Time.current.to_i
    date = Time.current.utc.strftime("%Y-%m-%d")
    credential_scope = "#{date}/#{VOD_SERVICE}/tc3_request"

    body = JSON.generate(payload)

    # 1. 拼接规范请求串
    http_method = "POST"
    canonical_uri = "/"
    canonical_querystring = ""
    canonical_headers = "content-type:application/json; charset=utf-8\nhost:#{VOD_API_HOST}\nx-tc-action:#{action.downcase}\n"
    signed_headers = "content-type;host;x-tc-action"
    hashed_payload = Digest::SHA256.hexdigest(body)
    canonical_request = "#{http_method}\n#{canonical_uri}\n#{canonical_querystring}\n#{canonical_headers}\n#{signed_headers}\n#{hashed_payload}"

    # 2. 拼接待签名字符串
    algorithm = "TC3-HMAC-SHA256"
    hashed_canonical_request = Digest::SHA256.hexdigest(canonical_request)
    string_to_sign = "#{algorithm}\n#{timestamp}\n#{credential_scope}\n#{hashed_canonical_request}"

    # 3. 计算签名
    secret_date = OpenSSL::HMAC.digest("SHA256", "TC3#{secret_key}", date)
    secret_service = OpenSSL::HMAC.digest("SHA256", secret_date, VOD_SERVICE)
    secret_signing = OpenSSL::HMAC.digest("SHA256", secret_service, "tc3_request")
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret_signing, string_to_sign)

    # 4. 构建 Authorization
    authorization = "#{algorithm} Credential=#{secret_id}/#{credential_scope}, SignedHeaders=#{signed_headers}, Signature=#{signature}"

    # 5. 发送请求
    uri = URI(VOD_API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 15

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json; charset=utf-8"
    request["Host"] = VOD_API_HOST
    request["X-TC-Action"] = action
    request["X-TC-Version"] = version
    request["X-TC-Timestamp"] = timestamp.to_s
    request["X-TC-Region"] = ""
    request["Authorization"] = authorization
    request.body = body

    response = http.request(request)
    JSON.parse(response.body)
  end

  # Base64 URL 安全编码（无填充）
  def self.base64url_encode(data)
    Base64.strict_encode64(data).tr('+/', '-_').gsub('=', '')
  end

  # 构建加密自适应码流信息（drmAdaptiveInfo）
  # drm_type: "simple_aes" / "widevine_fairplay" / "widevine" / "fairplay"
  # definition: 自适应码流模板 ID
  def self.build_drm_adaptive_info(drm_type, definition)
    case drm_type
    when "simple_aes"
      { "privateEncryptionDefinition" => definition }
    when "widevine_fairplay"
      { "multiDrmDefinition" => definition }
    when "widevine"
      { "widevineDefinition" => definition }
    when "fairplay"
      { "fairPlayDefinition" => definition }
    else
      { "privateEncryptionDefinition" => definition }
    end
  end
end
