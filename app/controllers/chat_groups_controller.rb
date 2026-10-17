class ChatGroupsController < ApplicationController
  before_action :check_plugin_enabled!

  def index
    @categories = ChatGroup::CATEGORIES
    @selected_category = params[:category]
    @chat_groups = ChatGroup.active.sorted
    @chat_groups = @chat_groups.by_category(@selected_category) if @selected_category.present?
    @chat_groups = @chat_groups.group_by(&:category)
  end

  private

  def check_plugin_enabled!
    unless Plugin.enabled.where(identifier: "chat_groups").exists?
      redirect_to root_path, alert: t("flash.chat_groups.disabled")
    end
  end
end
