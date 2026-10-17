class ApplicationController < ActionController::Base
  include LicenseVerification
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Chrome 80+ 覆盖国产手机浏览器（荣耀、华为、小米等内置浏览器基于 Chromium）
  allow_browser versions: { safari: "17.2", chrome: "80", firefox: "121", opera: "106", ie: false }

  # 跳过 admin 设置相关页面的 license 检查，否则 license 未配置时无法进入设置页面
  skip_before_action :check_license!, only: [:robots]

  before_action :set_locale
  before_action :touch_last_seen

  def robots
    render "robots", layout: false, content_type: "text/plain"
  end

  helper_method :demo_mode?
  helper_method :current_license_data

  private

  # 根据后台「系统语言」设置切换 I18n locale（支持 zh-CN / en）
  def set_locale
    locale = SiteSetting.get("site_locale", default: "zh-CN").to_s
    I18n.locale = I18n.available_locales.include?(locale.to_sym) ? locale.to_sym : I18n.default_locale
  end

  def demo_mode?
    ENV["DEMO_MODE"] == "true"
  end

  def current_license_data
    license_key.blank? ? nil : license_data
  end

  def touch_last_seen
    return unless current_user
    return if current_user.last_seen_at && current_user.last_seen_at > 2.minutes.ago
    current_user.update_column(:last_seen_at, Time.current)
  end

  def redirect_to_topic(topic, **opts)
    redirect_to url_for(controller: 'topics', action: 'show', node: topic.node.slug, slug: topic.slug), **opts
  end

  def topic_location(topic)
    { controller: 'topics', action: 'show', node: topic.node.slug, slug: topic.slug }
  end
end
