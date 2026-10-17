Rails.application.config.after_initialize do
  next if defined?(Rails::Command) && Rails::Command.respond_to?(:assets)

  if Rails.env.production? && ActiveRecord::Base.connection.active?
    Rails.logger.info "[AutoComment] Initializing scheduler on boot"
    AutoCommentSchedulerJob.set(wait: 2.minutes).perform_later
  end
end
