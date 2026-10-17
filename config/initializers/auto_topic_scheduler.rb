Rails.application.config.after_initialize do
  next if defined?(Rails::Command) && Rails::Command.respond_to?(:assets)

  if Rails.env.production? && ActiveRecord::Base.connection.active?
    Rails.logger.info "[AutoTopic] Initializing scheduler on boot"
    AutoTopicSchedulerJob.set(wait: 1.minute).perform_later
  end
end
