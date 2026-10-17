require "net/http"
require "uri"
require "json"

class AiTopicService
  DEFAULT_BASE_URL = AiCommentService::DEFAULT_BASE_URL
  DEFAULT_MODEL = AiCommentService::DEFAULT_MODEL

  DEFAULT_SYSTEM_PROMPT = <<~PROMPT.freeze
    你是一个活跃的社区成员，正在发帖讨论。
    请生成一个话题帖子的标题和内容。

    要求：
    1. 标题简洁有吸引力，4-120 个字符
    2. 内容自然口语化，像一个真实的开发者用户在分享或讨论
    3. 内容可以包含提问、经验分享、技术讨论、项目展示等
    4. 长度适中，内容 100-500 字
    5. 不要使用明显的 AI 语气（如"作为一个AI"等）
    6. 不要使用 markdown 格式（如加粗、标题等）
    7. 可以适当使用表情符号，但不要过多
    8. 请严格按以下格式输出，不要输出其他内容：

    标题：xxx
    内容：xxx
  PROMPT

  def self.generate(node: nil, system_prompt: nil, web_search: false)
    new.generate(node: node, system_prompt: system_prompt, web_search: web_search)
  end

  def generate(node:, system_prompt: nil, web_search: false)
    api_key = SiteSetting.get("ai_api_key")
    if api_key.blank?
      return { success: false, error: "AI API 密钥未配置，请先在系统设置中配置" }
    end

    base_url = SiteSetting.get("ai_base_url", default: DEFAULT_BASE_URL).gsub(%r{/+$}, "")
    model = SiteSetting.get("ai_model", default: DEFAULT_MODEL).presence || DEFAULT_MODEL

    input = build_input(node:, system_prompt:)

    uri = URI("#{base_url}/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{api_key}"
    body = {
      model: model,
      messages: input,
      stream: false
    }
    body[:tools] = [{ type: "web_search" }] if web_search
    request.body = JSON.generate(body)

    Rails.logger.info "[AiTopic] Calling API: #{uri} model=#{model}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 120) do |http|
      http.request(request)
    end

    result = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      error_msg = result.dig("error", "message") || result["message"] || response.message
      Rails.logger.error "[AiTopic] API error: #{response.code} - #{error_msg}"
      return { success: false, error: "AI 服务调用失败：#{error_msg}" }
    end

    output_text = extract_output_text(result)
    if output_text.blank?
      Rails.logger.error "[AiTopic] Empty response from API"
      return { success: false, error: "AI 未返回有效内容" }
    end

    cleaned_text = clean_output(output_text)
    title, content = parse_output(cleaned_text)

    if title.blank? || content.blank?
      Rails.logger.error "[AiTopic] Failed to parse title/content from: #{cleaned_text.truncate(100)}"
      return { success: false, error: "AI 返回格式异常，无法解析标题和内容" }
    end

    Rails.logger.info "[AiTopic] Generated topic: #{title.truncate(50)}"

    { success: true, title: title.strip, content: content.strip }
  rescue Net::OpenTimeout
    Rails.logger.error "[AiTopic] Connection timeout"
    { success: false, error: "AI 服务连接超时，请检查网络或稍后重试" }
  rescue Net::ReadTimeout
    Rails.logger.error "[AiTopic] Read timeout"
    { success: false, error: "AI 服务响应超时，请稍后重试" }
  rescue JSON::ParserError => e
    Rails.logger.error "[AiTopic] JSON parse error: #{e.message}"
    { success: false, error: "AI 服务返回数据异常" }
  rescue StandardError => e
    Rails.logger.error "[AiTopic] Service error: #{e.class} - #{e.message}"
    { success: false, error: "AI 服务异常：#{e.message}" }
  end

  private

  def build_input(node:, system_prompt: nil)
    system_message = system_prompt.presence || SiteSetting.get("ai_topic_prompt").presence || DEFAULT_SYSTEM_PROMPT

    user_message = ""
    if node.present?
      user_message += "话题分类：#{node.name}\n\n"
    end
    user_message += "请生成一个适合发布到社区的话题帖子。"

    [
      { role: "system", content: system_message },
      { role: "user", content: user_message }
    ]
  end

  def extract_output_text(result)
    result.dig("choices", 0, "message", "content")
  end

  def clean_output(text)
    text.gsub(%r{<think[^>]*>.*?</think}m, "")
        .gsub(%r{</?think>}m, "")
        .strip
  end

  def parse_output(text)
    # Try to split by "标题：" and "内容："
    title_match = text.match(/标题[：:]\s*(.*?)(?=\n\s*内容[：:])/m)
    content_match = text.match(/内容[：:]\s*(.*)/m)

    if title_match && content_match
      [ title_match[1].strip, content_match[1].strip ]
    else
      # Fallback: try just "标题："
      title_match = text.match(/标题[：:]\s*(.+)/m)
      if title_match
        remaining = text.sub(/标题[：:]\s*.+\n?/, "")
        content_match = remaining.match(/内容[：:]\s*(.*)/m)
        if content_match
          [ title_match[1].strip, content_match[1].strip ]
        else
          [ title_match[1].strip, remaining.strip ]
        end
      else
        # Last resort: first line as title, rest as content
        lines = text.split("\n", 2)
        [ lines[0], lines[1].to_s ]
      end
    end
  end
end
