require_dependency "application_controller"

class PluginsController < ApplicationController
  # 插件提供的公开 API，供前端调用
  before_action :find_plugin

  def execute
    hook_action = params[:hook_action]
    return render json: { code: 1, message: "缺少 hook_action 参数" }, status: :bad_request if hook_action.blank?
    return render json: { code: 1, message: "插件未启用" }, status: :forbidden unless @plugin.enabled?

    Myapp::PluginManager.instance.fire_global_hook("public_action_#{hook_action}", @plugin, params)

    render json: { code: 0, message: "success" }
  rescue StandardError => e
    Rails.logger.error("[PluginsController] Error: #{e.message}")
    render json: { code: 1, message: "插件执行错误: #{e.message}" }, status: :internal_server_error
  end

  private

  def find_plugin
    @plugin = Plugin.enabled.find_by(identifier: params[:identifier])
    render json: { code: 1, message: "插件不存在或未启用" }, status: :not_found if @plugin.nil?
  end
end
