require_dependency "admin/dashboard_controller"

# 插件&主题中心：浏览扩展市场并在线安装/升级插件与主题
class Admin::PluginCenterController < Admin::DashboardController
  before_action :set_tab

  def index
    @keyword = params[:keyword].to_s.strip
    @center_url = Myapp::PluginCenterClient.base_url
    @center_token = Myapp::PluginCenterClient.access_token
    @center_available = false
    @plugins = []
    @themes = []
    @error = nil

    begin
      @center_available = Myapp::PluginCenterClient.available?
      if @center_available
        if @tab == "themes"
          @themes = Myapp::PluginCenterClient.themes_list(keyword: @keyword)
        else
          @plugins = Myapp::PluginCenterClient.list(keyword: @keyword)
        end
      else
        @error = t("admin.ui.m995")
      end
    rescue StandardError => e
      @error = "#{t('admin.ui.m995')} (#{e.message})"
    end

    @local_plugins = Plugin.all.index_by(&:identifier)
    @local_themes = Theme.all.index_by(&:identifier)
  end

  # 配置插件&主题中心地址与接入令牌
  def update_settings
    url = params[:center_url].to_s.strip
    if url.present? && url !~ %r{\Ahttps?://\S+\z}
      redirect_to admin_plugin_center_path(tab: @tab), alert: t("admin.ui.m996")
      return
    end

    Myapp::PluginCenterClient.base_url = url
    Myapp::PluginCenterClient.access_token = params[:center_token].to_s.strip
    redirect_to admin_plugin_center_path(tab: @tab), notice: t("admin.ui.m997")
  end

  # 安装 / 升级插件
  def install
    identifier = params[:identifier].to_s
    plugin = Plugin.find_by(identifier: identifier)

    if plugin&.enabled? && plugin.version == params[:version].to_s
      redirect_to admin_plugins_path, notice: t("admin.ui.m998")
      return
    end

    Myapp::PluginCenterClient.install(identifier)
    redirect_to admin_plugins_path, notice: t("admin.ui.m999")
  rescue StandardError => e
    redirect_to admin_plugin_center_path(tab: @tab), alert: "#{t('admin.ui.m1000')}: #{e.message}"
  end

  # 安装 / 升级主题
  def install_theme
    identifier = params[:identifier].to_s
    theme = Theme.find_by(identifier: identifier)

    if theme && theme.version == params[:version].to_s && %w[installed active].include?(theme.status)
      redirect_to admin_themes_path, notice: t("admin.ui.m1010")
      return
    end

    Myapp::PluginCenterClient.install_theme(identifier)
    redirect_to admin_themes_path, notice: t("admin.ui.m1009")
  rescue StandardError => e
    redirect_to admin_plugin_center_path(tab: "themes"), alert: "#{t('admin.ui.m1011')}: #{e.message}"
  end

  private

  def set_tab
    @tab = params[:tab] == "themes" ? "themes" : "plugins"
  end
end
