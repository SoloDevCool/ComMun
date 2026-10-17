class AutoCommentSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    # Re-schedule self BEFORE doing anything, so the chain is never broken
    self.class.set(wait: 10.minutes).perform_later

    unless AutoCommentSchedulerService.enabled?
      Rails.logger.debug "[AutoComment] Feature disabled, skipping"
      return
    end

    # Prevent concurrent execution
    return unless Rails.cache.write("auto_comment_scheduler_lock", "1", expires_in: 15.minutes, unless_exist: true)

    begin
      today = Date.current
      daily_count = SiteSetting.get("auto_comment_daily_count", default: "0").to_i

      # Create today's tasks if not enough
      existing_count = AutoCommentTask.today.count
      if existing_count < daily_count
        AutoCommentSchedulerService.create_tasks_for_date!(today, daily_count - existing_count)
      end

      # Dispatch due pending tasks
      due_tasks = AutoCommentTask.today.pending.where("scheduled_at <= ?", Time.current)
      due_tasks.find_each do |task|
        AutoCommentGenerateJob.perform_later(task.id)
      end
    ensure
      Rails.cache.delete("auto_comment_scheduler_lock")
    end
  end
end
