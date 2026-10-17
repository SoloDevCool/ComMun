require "net/http"
require "uri"
require "json"

class AiCommentService
  DEFAULT_BASE_URL = "https://dashscope.aliyuncs.com/compatible-mode/v1"
  DEFAULT_MODEL = "qwen3.5-flash"

  def self.generate(topic:, parent_comment: nil, system_prompt: nil, web_search: false)
    new.generate(topic: topic, parent_comment: parent_comment, system_prompt: system_prompt, web_search: web_search)
  end

  def generate(topic:, parent_comment: nil, system_prompt: nil, web_search: false)
    api_key = SiteSetting.get("ai_api_key")
    if api_key.blank?
      return { success: false, error: "AI API 密钥未配置，请先在系统设置中配置" }
    end

    base_url = SiteSetting.get("ai_base_url", default: DEFAULT_BASE_URL).gsub(%r{/+$}, "")
    model = SiteSetting.get("ai_model", default: DEFAULT_MODEL).presence || DEFAULT_MODEL

    input = build_input(topic:, parent_comment:, system_prompt:)

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

    Rails.logger.info "[AiComment] Calling API: #{uri} model=#{model}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 120) do |http|
      http.request(request)
    end

    result = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      error_msg = result.dig("error", "message") || result["message"] || response.message
      Rails.logger.error "[AiComment] API error: #{response.code} - #{error_msg}"
      return { success: false, error: "AI 服务调用失败：#{error_msg}" }
    end

    output_text = extract_output_text(result)
    if output_text.blank?
      Rails.logger.error "[AiComment] Empty response from API"
      return { success: false, error: "AI 未返回有效内容" }
    end

    # Clean up the output: remove thinking tags if present
    cleaned_text = clean_output(output_text)

    Rails.logger.info "[AiComment] Generated comment: #{cleaned_text.truncate(100)}"

    { success: true, content: cleaned_text }
  rescue Net::OpenTimeout
    Rails.logger.error "[AiComment] Connection timeout"
    { success: false, error: "AI 服务连接超时，请检查网络或稍后重试" }
  rescue Net::ReadTimeout
    Rails.logger.error "[AiComment] Read timeout"
    { success: false, error: "AI 服务响应超时，请稍后重试" }
  rescue JSON::ParserError => e
    Rails.logger.error "[AiComment] JSON parse error: #{e.message}"
    { success: false, error: "AI 服务返回数据异常" }
  rescue StandardError => e
    Rails.logger.error "[AiComment] Service error: #{e.class} - #{e.message}"
    { success: false, error: "AI 服务异常：#{e.message}" }
  end

  private

  DEFAULT_SYSTEM_PROMPT = <<~PROMPT.freeze
    你是一个活跃的社区成员，正在参与讨论。
    请根据提供的话题内容和上下文，生成一条自然、真实的评论。

    要求：
    1. 语气自然口语化，像一个真实的开发者用户
    2. 内容与话题相关，可以是提问、补充、赞同、讨论或分享经验
    3. 长度适中，一般 20-200 字
    4. 不要使用明显的 AI 语气（如"作为一个AI"等）
    5. 不要使用 markdown 格式（如加粗、标题等）
    6. 可以适当使用表情符号，但不要过多
    7. 直接输出评论内容，不要加引号或其他包裹
  PROMPT

  def build_input(topic:, parent_comment:, system_prompt: nil)
    system_message = system_prompt.presence || SiteSetting.get("ai_comment_prompt").presence || DEFAULT_SYSTEM_PROMPT

    user_message = "话题标题：#{topic.title}\n\n话题内容：#{topic.content.truncate(2000)}"

    if parent_comment.present?
      user_message += "\n\n需要回复的评论：#{parent_comment.user.display_name} 说：#{parent_comment.content.truncate(500)}"
      user_message += "\n\n请针对这条评论写一条自然的回复。"
    else
      user_message += "\n\n请针对这个话题写一条自然的评论。"
    end

    [
      { role: "system", content: system_message },
      { role: "user", content: user_message }
    ]
  end

  def extract_output_text(result)
    result.dig("choices", 0, "message", "content")
  end

  def clean_output(text)
    # Remove <think...</think< blocks (reasoning output)
    text.gsub(%r{<think[^>]*>.*?</think}m, "")
       .gsub(%r{</?think>}m, "")
       .strip
  end
end
