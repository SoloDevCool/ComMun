class AutoCommentGenerateJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.minutes, attempts: 2

  def perform(task_id)
    task = AutoCommentTask.pending.find_by(id: task_id)
    return if task.nil?

    task.processing!

    # Select a random topic with comments_count < 50 (prefer less commented topics)
    topic = select_topic
    unless topic
      task.failed!("没有可用的话题")
      return
    end

    # Generate comment via AI
    result = AiCommentService.generate(topic: topic)
    unless result[:success]
      task.failed!(result[:error])
      return
    end

    # Publish comment via service
    service = CommentOperationService.new(
      topic_id: topic.id,
      content: result[:content]
    )
    publish_result = service.call

    if publish_result[:success]
      task.completed!(
        comment_content: result[:content],
        topic_id: topic.id,
        comment_id: publish_result[:comment].id
      )
      Rails.logger.info "[AutoComment] Published comment on: #{topic.title.truncate(30)}"
    else
      task.failed!(publish_result[:message])
    end
  rescue => e
    Rails.logger.error "[AutoComment] Job error: #{e.class} - #{e.message}"
    task&.failed!("#{e.class}: #{e.message}")
  end

  private

  def select_topic
    # Prefer topics with fewer comments (more natural to comment on quiet topics)
    candidates = Topic.where(pinned: false)
                      .where("comments_count < ?", 50)
                      .order(Arel.sql("RANDOM()"))
                      .limit(20)

    # Fallback to any topic if no low-comment topics found
    candidates = Topic.where(pinned: false).order(Arel.sql("RANDOM()")).limit(20) if candidates.empty?

    candidates.to_a.sample
  end
end
