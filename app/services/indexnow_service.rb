class IndexnowService
  INDEXNOW_ENDPOINT = "https://api.indexnow.org/IndexNow"

  def self.notify(url)
    enabled = SiteSetting.get("indexnow_enabled", default: "false")
    return unless enabled == "true"

    key = SiteSetting.get("indexnow_key", default: "")
    return if key.blank?

    host = URI.parse(url).host rescue nil
    return unless host

    # 通过 SolidQueue 异步执行，避免阻塞请求
    IndexnowNotifyJob.perform_later(url, key, host)
  end

  def self.ping(url, key, host)
    require "net/http"
    require "uri"
    require "json"

    uri = URI.parse(INDEXNOW_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10

    body = {
      host: host,
      key: key,
      urlList: Array(url)
    }

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request.body = body.to_json

    response = http.request(request)
    Rails.logger.info("[IndexNow] Ping #{url} - #{response.code} #{response.message}")
  rescue => e
    Rails.logger.warn("[IndexNow] Ping failed: #{e.message}")
  end
end
