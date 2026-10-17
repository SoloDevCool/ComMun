require "json"
require "uri"
require "net/http"

class TencentCaptchaService
  API_HOST = "captcha.tencentcloudapi.com"
  API_ENDPOINT = "https://#{API_HOST}"
  SERVICE = "captcha"
  API_VERSION = "2019-07-22"

  # 验证结果
  Result = Struct.new(
    :success,       # 是否验证通过
    :captcha_code,  # 验证码返回的状态码
    :captcha_msg,   # 状态描述
    :evil_level,    # 恶意等级
    :request_id,    # 请求ID
    keyword_init: true
  )

  # 校验验证码票据
  # ticket:    前端回调返回的票据
  # randstr:   前端回调返回的随机串
  # user_ip:   用户 IP 地址
  def self.verify(ticket:, randstr:, user_ip:)
    app_id = SiteSetting.get("tencent_captcha_app_id", default: "")
    app_secret_key = SiteSetting.get("tencent_captcha_app_secret_key", default: "")

    if app_id.blank? || app_secret_key.blank?
      Rails.logger.warn "[TencentCaptcha] 未配置 CaptchaAppId/AppSecretKey"
      return Result.new(success: false, captcha_code: -1, captcha_msg: "验证码未配置", evil_level: 0, request_id: nil)
    end

    payload = {
      "CaptchaType" => 9,
      "Ticket" => ticket,
      "UserIp" => user_ip,
      "Randstr" => randstr,
      "CaptchaAppId" => app_id.to_i,
      "AppSecretKey" => app_secret_key
    }

    response = call_api("DescribeCaptchaResult", payload)
    parse_response(response)
  rescue => e
    Rails.logger.error "[TencentCaptcha] 验证失败: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n") if e.backtrace
    Result.new(success: false, captcha_code: -1, captcha_msg: "验证服务异常: #{e.message}", evil_level: 0, request_id: nil)
  end

  # 是否启用
  def self.enabled?
    SiteSetting.get("tencent_captcha_enabled", default: "false") == "true"
  end

  # 获取前端所需的 CaptchaAppId（仅 AppId，不含密钥）
  def self.app_id
    SiteSetting.get("tencent_captcha_app_id", default: "")
  end

  private

  def self.call_api(action, payload)
    timestamp = Time.current.to_i
    date = Time.current.utc.strftime("%Y-%m-%d")
    credential_scope = "#{date}/#{SERVICE}/tc3_request"

    body = JSON.generate(payload)

    http_method = "POST"
    canonical_uri = "/"
    canonical_querystring = ""
    canonical_headers = "content-type:application/json; charset=utf-8\nhost:#{API_HOST}\nx-tc-action:#{action.downcase}\n"
    signed_headers = "content-type;host;x-tc-action"
    hashed_payload = Digest::SHA256.hexdigest(body)
    canonical_request = "#{http_method}\n#{canonical_uri}\n#{canonical_querystring}\n#{canonical_headers}\n#{signed_headers}\n#{hashed_payload}"

    algorithm = "TC3-HMAC-SHA256"
    hashed_canonical_request = Digest::SHA256.hexdigest(canonical_request)
    string_to_sign = "#{algorithm}\n#{timestamp}\n#{credential_scope}\n#{hashed_canonical_request}"

    secret_id = SiteSetting.get("tencent_captcha_secret_id", default: "")
    secret_key = SiteSetting.get("tencent_captcha_secret_key", default: "")

    secret_date = OpenSSL::HMAC.digest("SHA256", "TC3#{secret_key}", date)
    secret_service = OpenSSL::HMAC.digest("SHA256", secret_date, SERVICE)
    secret_signing = OpenSSL::HMAC.digest("SHA256", secret_service, "tc3_request")
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret_signing, string_to_sign)

    authorization = "#{algorithm} Credential=#{secret_id}/#{credential_scope}, SignedHeaders=#{signed_headers}, Signature=#{signature}"

    uri = URI(API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 5

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json; charset=utf-8"
    request["Host"] = API_HOST
    request["X-TC-Action"] = action
    request["X-TC-Version"] = API_VERSION
    request["X-TC-Timestamp"] = timestamp.to_s
    request["Authorization"] = authorization
    request.body = body

    response = http.request(request)
    JSON.parse(response.body)
  end

  def self.parse_response(response)
    resp = response["Response"]

    unless resp
      return Result.new(success: false, captcha_code: -1, captcha_msg: "响应格式异常", evil_level: 0, request_id: nil)
    end

    if resp["Error"]
      code = resp["Error"]["Code"]
      message = resp["Error"]["Message"]
      Rails.logger.error "[TencentCaptcha] API 错误: #{code}: #{message}"
      return Result.new(success: false, captcha_code: -1, captcha_msg: "#{code}: #{message}", evil_level: 0, request_id: resp["RequestId"])
    end

    captcha_code = resp["CaptchaCode"]
    captcha_msg = resp["CaptchaMsg"] || ""
    evil_level = resp["EvilLevel"] || 0
    request_id = resp["RequestId"]

    success = captcha_code == 1

    unless success
      Rails.logger.warn "[TencentCaptcha] 验证失败: code=#{captcha_code}, msg=#{captcha_msg}"
    end

    Result.new(success: success, captcha_code: captcha_code, captcha_msg: captcha_msg, evil_level: evil_level, request_id: request_id)
  end
end
