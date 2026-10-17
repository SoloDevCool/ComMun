class AutoTopicGenerateJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.minutes, attempts: 2

  def perform(task_id)
    task = AutoTopicTask.pending.find_by(id: task_id)
    return if task.nil?

    task.processing!

    # Select a random node
    node = select_node
    unless node
      task.failed!("没有可用的版块分类")
      return
    end

    # Generate topic via AI
    result = AiTopicService.generate(node: node)
    unless result[:success]
      task.failed!(result[:error])
      return
    end

    # Save or publish based on configured mode
    mode = SiteSetting.get("auto_topic_mode", default: "draft")
    user = pick_user

    if mode == "publish"
      service = TopicOperationService.new(
        title: result[:title],
        content: result[:content],
        node_id: node.id
      )
      publish_result = service.call

      if publish_result[:success]
        task.completed!(topic_title: result[:title], topic_id: publish_result[:topic].id, action: "publish")
        Rails.logger.info "[AutoTopic] Published: #{result[:title].truncate(30)}"
      else
        task.failed!(publish_result[:message])
      end
    else
      draft = TopicDraft.create!(
        title: result[:title],
        content: result[:content],
        node: node,
        user: user
      )
      task.completed!(topic_title: result[:title], draft_id: draft.id, action: "draft")
      Rails.logger.info "[AutoTopic] Saved draft: #{result[:title].truncate(30)}"
    end
  rescue => e
    Rails.logger.error "[AutoTopic] Job error: #{e.class} - #{e.message}"
    task&.failed!("#{e.class}: #{e.message}")
  end

  private

  def select_node
    Node.system_ordered.to_a.sample || Node.interest_ordered.to_a.sample
  end

  def pick_user
    User.operational.order("RANDOM()").first || User.where(admin: true).first
  end
end
