# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = true

  # Output structured JSON log lines
  config.lograge.formatter = Lograge::Formatters::Json.new

  # Customize which fields appear in each log entry
  config.lograge.custom_options = lambda do |event|
    {
      time: event.time,
      host: event.payload[:host],
      params: event.payload[:params].except("controller", "action"),
      user_id: event.payload[:user_id],
      request_id: event.payload[:request_id],
      remote_ip: event.payload[:remote_ip]
    }
  end

  # Log ActiveRecord SQL queries (via lograge-sql)
  config.lograge_sql.extract_event = proc do |event|
    {
      name: event.payload[:name],
      sql: event.payload[:sql].tr("\n", " ").squeeze(" "),
      duration: event.duration.to_f.round(2)
    }
  end

  config.lograge_sql.single_line = true

  # Keep ActiveSupport::TaggedLogging tags (e.g. request_id) in JSON output
  config.lograge.keep_original_rails_log_format = false
  config.lograge.base_controller_class = "ActionController::Base"
end
