class IndexnowNotifyJob < ApplicationJob
  queue_as :default

  def perform(url, key, host)
    IndexnowService.ping(url, key, host)
  end
end
