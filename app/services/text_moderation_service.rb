require "json"
require "base64"
require "openssl"
require "uri"
require "net/http"
require "digest"

class TextModerationService
  TMS_API_HOST = "tms.tencentcloudapi.com"
  TMS_API_ENDPOINT = "https://#{TMS_API_HOST}"
  TMS_SERVICE = "tms"
  TMS_API_VERSION = "2020-12-29"

  # 检测结果结构
  Result = Struct.new(
    :suggestion,    # "Pass" | "Block" | "Review"
    :label,         # "Normal" | "Porn" | "Abuse" | "Ad" | ...
    :sub_label,     # 二级标签
    :score,         # 置信度 0-100
    :keywords,      # 命中的关键词
    :detail_results,
    :request_id,
    :raw_response,
    keyword_init: true
  )

  # 检查文本是否通过安全检测
  # 返回 Result 结构体，或出错时返回 nil
  # 错误信息写入 @last_error，可由 check_simple 读取
  def self.check(text, options = {})
    @last_error = nil
    return nil if text.blank?

    secret_id = SiteSetting.get("tencent_tms_secret_id", default: "")
    secret_key = SiteSetting.get("tencent_tms_secret_key", default: "")

    if secret_id.blank? || secret_key.blank?
      @last_error = "未配置 SecretId/SecretKey"
      Rails.logger.warn "[TextModeration] 未配置 SecretId/SecretKey，跳过文本检测"
      return nil
    end

    payload = build_payload(text, options)
    response = call_api("TextModeration", payload, secret_id, secret_key)
    parse_response(response)
  rescue => e
    @last_error = e.message
    Rails.logger.error "[TextModeration] 检测失败: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n") if e.backtrace
    nil
  end

  # 上次 check 调用的错误信息
  def self.last_error
    @last_error
  end

  # 检测文本，返回简化的哈希 { suggestion:, label:, message:, error: }
  def self.check_simple(text, options = {})
    result = check(text, options)
    if result.nil?
      error_msg = last_error || "未知错误"
      Rails.logger.error "[TextModeration] check_simple 返回 nil，原因: #{error_msg}"
      return { error: "检测服务调用失败：#{error_msg}。请检查日志获取详细信息。" }
    end

    message = case result.suggestion
              when "Block"
                "内容包含违规信息（#{label_name(result.label)}），禁止发布"
              when "Review"
                "内容需要人工审核（#{label_name(result.label)}），已提交审核队列"
              else
                "内容安全"
              end

    {
      suggestion: result.suggestion,
      label: result.label,
      sub_label: result.sub_label,
      score: result.score,
      keywords: result.keywords,
      message: message
    }
  end

  # 检测并判定：Block 返回错误消息，Review/Pass 返回 nil（通过）
  def self.check_and_reject!(text, options = {})
    result = check(text, options)
    return nil if result.nil? # 未启用时视为通过

    case result.suggestion
    when "Block"
      return "内容包含违规信息（#{label_name(result.label)}），禁止发布。如有疑问请联系管理员。"
    end
    nil
  end

  # 判断是否启用
  def self.enabled?
    SiteSetting.get("text_moderation_enabled", default: "false") == "true"
  end

  def self.label_name(label)
    labels = {
      "Normal" => "正常",
      "Porn" => "色情",
      "Abuse" => "谩骂",
      "Ad" => "广告",
      "Polity" => "政治敏感",
      "Illegal" => "违法犯罪",
      "Terror" => "暴恐",
      "Spam" => "垃圾信息",
      "Flood" => "灌水"
    }
    labels[label] || label
  end

  private

  def self.build_payload(text, options = {})
    payload = {
      "Content" => Base64.strict_encode64(text.encode("UTF-8"))
    }

    biz_type = options[:biz_type] || SiteSetting.get("tencent_tms_biz_type", default: "")
    payload["BizType"] = biz_type if biz_type.present?

    source_language = options[:source_language] || SiteSetting.get("tencent_tms_source_language", default: "zh")
    payload["SourceLanguage"] = source_language if source_language.present?

    data_id = options[:data_id]
    payload["DataId"] = data_id if data_id.present?

    payload["Type"] = options[:type] if options[:type].present?

    payload
  end

  def self.call_api(action, payload, secret_id, secret_key)
    timestamp = Time.current.to_i
    date = Time.current.utc.strftime("%Y-%m-%d")
    region = SiteSetting.get("tencent_tms_region", default: "ap-guangzhou")
    credential_scope = "#{date}/#{TMS_SERVICE}/tc3_request"

    body = JSON.generate(payload)

    http_method = "POST"
    canonical_uri = "/"
    canonical_querystring = ""
    canonical_headers = "content-type:application/json; charset=utf-8\nhost:#{TMS_API_HOST}\nx-tc-action:#{action.downcase}\n"
    signed_headers = "content-type;host;x-tc-action"
    hashed_payload = Digest::SHA256.hexdigest(body)
    canonical_request = "#{http_method}\n#{canonical_uri}\n#{canonical_querystring}\n#{canonical_headers}\n#{signed_headers}\n#{hashed_payload}"

    algorithm = "TC3-HMAC-SHA256"
    hashed_canonical_request = Digest::SHA256.hexdigest(canonical_request)
    string_to_sign = "#{algorithm}\n#{timestamp}\n#{credential_scope}\n#{hashed_canonical_request}"

    secret_date = OpenSSL::HMAC.digest("SHA256", "TC3#{secret_key}", date)
    secret_service = OpenSSL::HMAC.digest("SHA256", secret_date, TMS_SERVICE)
    secret_signing = OpenSSL::HMAC.digest("SHA256", secret_service, "tc3_request")
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret_signing, string_to_sign)

    authorization = "#{algorithm} Credential=#{secret_id}/#{credential_scope}, SignedHeaders=#{signed_headers}, Signature=#{signature}"

    uri = URI(TMS_API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 5

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json; charset=utf-8"
    request["Host"] = TMS_API_HOST
    request["X-TC-Action"] = action
    request["X-TC-Version"] = TMS_API_VERSION
    request["X-TC-Timestamp"] = timestamp.to_s
    request["X-TC-Region"] = region
    request["Authorization"] = authorization
    request.body = body

    response = http.request(request)
    JSON.parse(response.body)
  end

  def self.parse_response(response)
    resp = response["Response"]

    unless resp
      @last_error = "响应格式异常: #{response}"
      Rails.logger.error "[TextModeration] 响应格式异常: #{response}"
      return nil
    end

    if resp["Error"]
      @last_error = "#{resp['Error']['Code']}: #{resp['Error']['Message']}"
      Rails.logger.error "[TextModeration] API 错误: #{@last_error}"
      return nil
    end

    Result.new(
      suggestion: resp["Suggestion"] || "Pass",
      label: resp["Label"] || "Normal",
      sub_label: resp["SubLabel"] || "",
      score: resp["Score"] || 0,
      keywords: resp["Keywords"] || [],
      detail_results: resp["DetailResults"],
      request_id: resp["RequestId"],
      raw_response: resp
    )
  end
end
