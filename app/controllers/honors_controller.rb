class HonorsController < ApplicationController
  before_action :check_plugin_enabled!

  def index
    @honors = Honor.active.includes(:user).ordered
  end

  private

  def check_plugin_enabled!
    plugin = Plugin.enabled.find_by(identifier: "honors")
    unless plugin
      redirect_to root_path, alert: t("flash.honors.disabled")
    end
  end
end
