class Admin::AppearanceSettingsController < Admin::DashboardController
  before_action :require_super_admin!

  NAV_MODULES = [
    { key: "community",       name: "社区",   icon: "bi-house-door",        setting_key: nil,                  default_enabled: true  }
  ].freeze

  def index
    @license_valid = license_valid?
    @appearance = SiteAppearance.instance
    @nav_modules = ordered_nav_modules
  end

  def update
    unless license_valid?
      redirect_to admin_settings_path, alert: t("admin.flash.m008")
      return
    end

    @appearance = SiteAppearance.instance

    if params.dig(:site_appearance, :remove_logo) == "1"
      @appearance.remove_logo_from_cos!
      @appearance.logo.purge_later
    end
    if params.dig(:site_appearance, :remove_favicon) == "1"
      @appearance.remove_favicon_from_cos!
      @appearance.favicon.purge_later
    end

    if params[:site_appearance].present?
      @appearance.update(appearance_params)
    end

    # 保存导航栏排序
    if params[:nav_module_order].present?
      SiteSetting.set("nav_module_order", params[:nav_module_order])
    end

    redirect_to admin_appearance_settings_path, notice: t("admin.flash.m040")
  end

  # 专门保存导航栏排序（AJAX 调用）
  def update_nav_order
    unless license_valid?
      render json: { error: t("admin.flash.m007") }, status: :forbidden
      return
    end

    if params[:module_keys].is_a?(Array)
      SiteSetting.set("nav_module_order", params[:module_keys].to_json)
      render json: { ok: true }
    else
      render json: { error: t("admin.flash.m083") }, status: :unprocessable_entity
    end
  end

  private

  def appearance_params
    params.require(:site_appearance).permit(:logo, :favicon, :logo_display_mode)
  end

  def require_super_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: t("admin.flash.m085")
    end
  end

  # 获取按自定义顺序排列的导航模块（含启用状态）
  def ordered_nav_modules
    saved_order = SiteSetting.get("nav_module_order")
    ordered_keys = saved_order.present? ? JSON.parse(saved_order) : NAV_MODULES.map { |m| m[:key] }

    # 确保所有已知模块都包含在内，并保留用户自定义的新增顺序
    ordered_keys |= NAV_MODULES.map { |m| m[:key] }

    ordered_keys.filter_map do |key|
      mod = NAV_MODULES.find { |m| m[:key] == key }
      next unless mod

      enabled = if mod[:setting_key].present?
        SiteSetting.get(mod[:setting_key], default: mod[:default_enabled].to_s) == "true"
      else
        true
      end

      self.class.translated_nav_module(mod).merge(enabled: enabled)
    end
  end

  # 模块名称按当前 I18n locale 翻译（name 为缺省回退值）
  def self.translated_nav_module(mod)
    mod.merge(name: I18n.t("nav.#{mod[:key]}", default: mod[:name]))
  end

  # 模块 key -> 路径映射（题库/课程路径分别由 question_banks / courses 插件提供）
  NAV_PATH_MAP = {
    "community"      => "/topics",
    "chat_groups"    => "/chat_groups"
  }.freeze

  # 供外部调用：获取第一个已启用模块的路径
  def self.home_path
    first = nav_modules_for_frontend.first
    first ? NAV_PATH_MAP[first[:key]] : "/topics"
  end

  # 供外部调用的类方法：返回前台导航栏模块（排序+仅已启用的）
  def self.nav_modules_for_frontend
    saved_order = SiteSetting.get("nav_module_order")
    ordered_keys = saved_order.present? ? JSON.parse(saved_order) : NAV_MODULES.map { |m| m[:key] }
    ordered_keys |= NAV_MODULES.map { |m| m[:key] }

    ordered_keys.filter_map do |key|
      mod = NAV_MODULES.find { |m| m[:key] == key }
      next unless mod

      enabled = if mod[:setting_key].present?
        SiteSetting.get(mod[:setting_key], default: mod[:default_enabled].to_s) == "true"
      else
        true
      end

      next unless enabled

      translated_nav_module(mod).merge(enabled: true)
    end
  end
end
