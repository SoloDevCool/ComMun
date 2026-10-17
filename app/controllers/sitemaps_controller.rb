class SitemapsController < ApplicationController
  def index
    @topics = Topic.order(updated_at: :desc).limit(1000)
    @kols = Plugin.enabled.where(identifier: "kols").exists? ? Kol.active.ordered : []
    @chat_groups_enabled = Plugin.enabled.where(identifier: "chat_groups").exists?
    @chat_groups = @chat_groups_enabled ? ChatGroup.all : []
    @last_topic_updated = @topics.first&.updated_at

    respond_to do |format|
      format.xml { render layout: false }
    end
  end
end
