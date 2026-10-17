class AiGenerateJob < ApplicationJob
  queue_as :default

  def perform(task_id:, type:, **kwargs)
    # Mark as running
    Rails.cache.write(cache_key(task_id), { status: "running" }, expires_in: 5.minutes)

    result = case type
    when "topic"
      node = kwargs[:node_id].present? ? Node.find_by(id: kwargs[:node_id]) : nil
      AiTopicService.generate(node: node, system_prompt: kwargs[:system_prompt], web_search: kwargs[:web_search])
    when "comment"
      topic = Topic.find_by(id: kwargs[:topic_id])
      parent_comment = kwargs[:parent_id].present? ? Comment.find_by(id: kwargs[:parent_id]) : nil
      AiCommentService.generate(topic: topic, parent_comment: parent_comment, system_prompt: kwargs[:system_prompt], web_search: kwargs[:web_search])
    else
      { success: false, error: "Unknown generation type: #{type}" }
    end

    # Store result
    Rails.cache.write(cache_key(task_id), { status: "completed", result: result }, expires_in: 5.minutes)
  rescue => e
    Rails.logger.error "[AiGenerateJob] Error: #{e.class} - #{e.message}"
    Rails.cache.write(cache_key(task_id), { status: "completed", result: { success: false, error: "AI 生成失败：#{e.message}" } }, expires_in: 5.minutes)
  end

  private

  def cache_key(task_id)
    "ai_generate:#{task_id}"
  end
end
