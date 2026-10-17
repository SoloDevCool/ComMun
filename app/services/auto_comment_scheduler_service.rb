class AutoCommentSchedulerService
  def self.create_tasks_for_date!(date, count)
    start_hour = SiteSetting.get("auto_comment_time_start", default: "8").to_i.clamp(0, 23)
    end_hour = SiteSetting.get("auto_comment_time_end", default: "22").to_i.clamp(0, 23)

    base = date.to_time.change(hour: 0, min: 0, sec: 0)
    start_time = base + start_hour.hours
    end_time = base + [end_hour, 23].min.hours + 59.minutes + 59.seconds

    if start_time >= end_time
      Rails.logger.warn "[AutoComment] Invalid time range: #{start_hour}:00 - #{end_hour}:59"
      return
    end

    count.times do
      scheduled_at = rand(start_time..end_time)
      AutoCommentTask.create!(
        scheduled_date: date,
        scheduled_at: scheduled_at,
        status: :pending
      )
    end

    Rails.logger.info "[AutoComment] Scheduled #{count} tasks for #{date}"
  end

  def self.today_task_count
    AutoCommentTask.today.count
  end

  def self.enabled?
    SiteSetting.get("auto_comment_enabled", default: "false") == "true" &&
      SiteSetting.get("auto_comment_daily_count", default: "0").to_i > 0
  end
end
