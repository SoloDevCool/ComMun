require "digest"
require "json"
require "time"
require "openssl"
require "net/http"
require "uri"

class TencentSesEmailService
  API_HOST = "ses.tencentcloudapi.com"
  API_ENDPOINT = "https://#{API_HOST}"
  SERVICE = "ses"
  VERSION = "2020-03-10"
  ACTION = "SendEmail"
  ALGORITHM = "TC3-HMAC-SHA256"
  CONTENT_TYPE = "application/json; charset=utf-8"

  def self.send_email(to:, subject:, body:, from: nil)
    new.send_email(to: to, subject: subject, body: body, from: from)
  end

  def send_email(to:, subject:, body:, from: nil)
    secret_id = SiteSetting.get("tencent_ses_secret_id")
    secret_key = SiteSetting.get("tencent_ses_secret_key")
    from_email = from || SiteSetting.get("tencent_ses_from_email")
    region = SiteSetting.get("tencent_ses_region", default: "ap-guangzhou")

    if secret_id.blank? || secret_key.blank?
      return { success: false, message: "腾讯云邮件推送未配置，请在管理控制台设置 SecretId 和 SecretKey" }
    end

    if from_email.blank?
      return { success: false, message: "腾讯云邮件推送未配置发件人邮箱" }
    end

    payload = {
      FromAddress: from_email,
      ToAddresses: [to],
      Subject: subject,
      Html: { Html: body }
    }.to_json

    timestamp = Time.current.to_i
    date = Time.at(timestamp).utc.strftime("%Y-%m-%d")
    credential_scope = "#{date}/#{SERVICE}/tc3_request"

    # Step 1: Build canonical request
    canonical_headers = "content-type:#{CONTENT_TYPE}\nhost:#{API_HOST}\nx-tc-action:#{ACTION.downcase}\n"
    signed_headers = "content-type;host;x-tc-action"
    hashed_payload = Digest::SHA256.hexdigest(payload)

    canonical_request = [
      "POST",
      "/",
      "",
      canonical_headers,
      signed_headers,
      hashed_payload
    ].join("\n")

    # Step 2: Build string to sign
    string_to_sign = [
      ALGORITHM,
      timestamp.to_s,
      credential_scope,
      Digest::SHA256.hexdigest(canonical_request)
    ].join("\n")

    # Step 3: Calculate signature
    digest = OpenSSL::Digest.new("sha256")
    secret_date = OpenSSL::HMAC.digest(digest, "TC3" + secret_key, date)
    secret_service = OpenSSL::HMAC.digest(digest, secret_date, SERVICE)
    secret_signing = OpenSSL::HMAC.digest(digest, secret_service, "tc3_request")
    signature = OpenSSL::HMAC.hexdigest(digest, secret_signing, string_to_sign)

    # Step 4: Build authorization
    authorization = "#{ALGORITHM} Credential=#{secret_id}/#{credential_scope}, SignedHeaders=#{signed_headers}, Signature=#{signature}"

    # Send request
    uri = URI.parse(API_ENDPOINT)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = CONTENT_TYPE
    request["Host"] = API_HOST
    request["X-TC-Action"] = ACTION
    request["X-TC-Version"] = VERSION
    request["X-TC-Timestamp"] = timestamp.to_s
    request["X-TC-Region"] = region
    request["Authorization"] = authorization
    request.body = payload

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 10) do |http|
      http.request(request)
    end

    parsed = JSON.parse(response.body)

    if parsed["Response"] && parsed["Response"]["RequestId"]
      error = parsed["Response"]["Error"]
      if error
        { success: false, message: "邮件发送失败: #{error['Message']}" }
      else
        { success: true, message: "邮件发送成功" }
      end
    else
      { success: false, message: "邮件服务返回数据异常" }
    end
  rescue JSON::ParserError
    { success: false, message: "邮件服务返回数据异常" }
  rescue Net::OpenTimeout, Net::ReadTimeout
    { success: false, message: "邮件服务连接超时，请稍后重试" }
  rescue StandardError => e
    { success: false, message: "邮件发送失败: #{e.message}" }
  end
end
