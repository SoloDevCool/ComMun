module ApplicationHelper

  # 渲染版块图标：优先显示上传图片（自动裁剪为正方形，SVG 矢量图直接原样输出），
  # 其次为内联 SVG 代码图标，否则显示 Emoji/文字
  def node_icon(node, size: nil)
    return "📄" unless node

    if node.icon_file.attached?
      css_size = size || "1.3em"
      icon_image = node.icon_file_svg? ? node.icon_file : node.icon_file.variant(resize_to_fill: [128, 128])
      image_tag icon_image,
                style: "width:#{css_size};height:#{css_size};object-fit:contain;border-radius:4px;vertical-align:middle;",
                alt: node.name
    elsif node.respond_to?(:icon_svg_code?) && node.icon_svg_code?
      css_size = size || "1.3em"
      svg = node.icon
      # 安全校验：仅放行 <svg> 开头且不含脚本/事件属性的代码
      return "📄" if svg.match?(/<script|on\w+\s*=/i)

      content_tag :span, svg.html_safe,
                  class: "node-svg-icon",
                  style: "width:#{css_size};height:#{css_size};display:inline-flex;align-items:center;justify-content:center;vertical-align:middle;overflow:hidden;"
    else
      node.icon.presence || "📄"
    end
  end

  def site_name
    @site_name ||= SiteSetting.get("site_name", default: "Commun")
  end

  def site_appearance
    @site_appearance ||= SiteAppearance.instance
  end

  def site_logo_url
    return site_appearance.logo_url if site_appearance.logo_url.present?
    site_appearance.logo.attached? ? url_for(site_appearance.logo) : nil
  end

  def site_logo_display_mode
    site_appearance.logo_display_mode.presence || "text"
  end

  def site_favicon_url
    return site_appearance.favicon_url if site_appearance.favicon_url.present?
    site_appearance.favicon.attached? ? url_for(site_appearance.favicon) : nil
  end

  def highlight_keyword(text, keyword)
    return text if keyword.blank? || text.blank?
    escaped = Regexp.escape(keyword)
    text.gsub(/(#{escaped})/i, '<mark>\1</mark>').html_safe
  end

  def user_link_to(user, **opts)
    return user.display_name unless user
    if user_signed_in? && user == current_user
      link_to user.display_name, profile_path, **opts
    elsif user.profile_public?
      link_to user.display_name, user_path(user), **opts
    else
      user.display_name
    end
  end

  def can_manage_topic?(topic)
    return false unless user_signed_in?
    return true if current_user.admin?
    topic.user == current_user && topic.created_at > 15.minutes.ago
  end

  def user_initial(user)
    user&.display_name&.first&.upcase || 'U'
  end

  def render_mentions(content)
    return content if content.blank?

    rendered = content.gsub(/@([a-zA-Z0-9_\u4e00-\u9fa5]+)/) do |match|
      username = $1
      user = User.find_by(username: username)

      if user && (user_signed_in? ? user == current_user : false) || user&.profile_public?
        link_to "@#{username}", profile_path, class: "mention-link"
      elsif user&.profile_public?
        link_to "@#{username}", user_path(user), class: "mention-link"
      else
        match
      end
    end

    simple_format(rendered).html_safe
  end

  def ai_label_enabled?
    SiteSetting.get("ai_label_enabled", default: "false") == "true"
  end

  # 主题列表样式：article = 文章列表模式（默认），image_text = 图文列表模式
  # 按主题存储：优先读取当前启用主题的设置，无启用主题时回退到系统默认主题
  def topic_list_style
    (Theme.active_theme || Theme.default_theme)&.topic_list_style || "article"
  end

  def official_badge(user)
    return "" unless user&.admin? || user&.operator?
    tag.span("官方", class: "badge bg-warning text-dark rounded-pill official-badge", style: "font-size:0.6rem;padding:1px 5px;font-weight:500")
  end

  def user_link_to_with_official(user, **opts)
    return user.display_name unless user
    if user_signed_in? && user == current_user
      link_to(user.display_name, profile_path, **opts).concat(official_badge(user)).html_safe
    elsif user.profile_public?
      link_to(user.display_name, user_path(user), **opts).concat(official_badge(user)).html_safe
    else
      user.display_name + official_badge(user).html_safe
    end
  end

  # Override topic_path/topic_url to use /:node/:slug format
  def topic_path(topic_or_id, **options)
    if topic_or_id.is_a?(Topic)
      node = topic_or_id.node&.slug || 'general'
      "/#{node}/#{topic_or_id.url_slug}"
    else
      super
    end
  end

  def topic_url(topic_or_id, **options)
    if topic_or_id.is_a?(Topic)
      node = topic_or_id.node&.slug || 'general'
      "#{request.protocol}#{request.host_with_port}/#{node}/#{topic_or_id.url_slug}"
    else
      super
    end
  end

  # 插件相关辅助方法
  def render_plugin_injections(location)
    injections = Myapp::PluginManager.instance.view_injections_for(location).map do |injection|
      plugin = Plugin.enabled.find_by(identifier: injection[:plugin_id])
      next unless plugin&.enabled?

      if injection[:partial]
        partial_path = plugin.plugin_dir.join("views", injection[:partial])
        # 注：render(file:) 在 Rails 8 下返回未编译的源码文本，
        # 这里读取内容以 inline ERB 方式编译渲染
        partial_path.exist? ? render(inline: partial_path.read, type: :erb) : nil
      elsif injection[:content]
        injection[:content].html_safe
      end
    end.compact

    safe_join(injections) if injections.present?
  end

  def plugin_nav_items
    Myapp::PluginManager.instance.nav_items
  end

  def plugin_admin_nav_items
    Myapp::PluginManager.instance.admin_nav_items
  end

  def status_badge_class(status)
    case status
    when 'enabled' then 'bg-success'
    when 'installed' then 'bg-secondary'
    when 'disabled' then 'bg-warning text-dark'
    else 'bg-light text-dark'
    end
  end
end
