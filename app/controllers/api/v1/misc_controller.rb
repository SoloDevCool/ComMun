class Api::V1::MiscController < Api::V1::BaseController
  # GET /api/v1/chat_groups
  def chat_groups
    unless Plugin.enabled.where(identifier: "chat_groups").exists?
      return render_success(data: { enabled: false, groups: {} })
    end

    chat_groups = ChatGroup.active.sorted
    groups = chat_groups.group_by(&:category)

    render_success(
      data: {
        enabled: true,
        groups: groups.transform_values do |items|
          items.map { |g| { id: g.id, name: g.name, description: g.description, members_count: g.members_count, logo: group_logo_url(g) } }
        end
      }
    )
  end

  private

  def group_logo_url(group)
    return nil unless group.logo.attached?
    Rails.application.routes.url_helpers.rails_blob_path(group.logo, only_path: true)
  rescue StandardError
    nil
  end

  # GET /api/v1/site_info
  def site_info
    appearance = SiteAppearance.instance

    fake_users = SiteSetting.get("fake_users_count", default: "0").to_i
    fake_topics = SiteSetting.get("fake_topics_count", default: "0").to_i
    fake_comments = SiteSetting.get("fake_comments_count", default: "0").to_i

    data = {
      site_name: SiteSetting.get("site_name", default: "Commun"),
      site_title: SiteSetting.get("seo_title", default: "Commun - AI社区"),
      site_description: SiteSetting.get("seo_description", default: ""),
      logo_url: nil,
      favicon_url: nil,
      stats: {
        users_count: User.count + fake_users,
        topics_count: Topic.count + fake_topics,
        comments_count: Comment.count + fake_comments
      },
      features: {
        registration_enabled: SiteSetting.get("registration_enabled", default: "true") != "false",
        invitation_code_required: InvitationCode.requirement_enabled?,
        friend_links_enabled: SiteSetting.get("friend_links_enabled", default: "false") == "true",
        chat_groups_enabled: Plugin.enabled.where(identifier: "chat_groups").exists?,
        tools_enabled: Plugin.enabled.where(identifier: "tools").exists?,
        shop_enabled: Plugin.enabled.where(identifier: "shop").exists?,
        kols_enabled: Plugin.enabled.where(identifier: "kols").exists?,
        captcha_enabled: TencentCaptchaService.enabled?,
        captcha_app_id: TencentCaptchaService.app_id
      },
      nav_modules: Admin::AppearanceSettingsController.nav_modules_for_frontend.map { |m| { key: m[:key], name: m[:name], icon: m[:icon] } },
      home_module: Admin::AppearanceSettingsController.nav_modules_for_frontend.first&.dig(:key) || "community"
    }

    if appearance&.logo&.attached?
      data[:logo_url] = Rails.application.routes.url_helpers.rails_blob_path(appearance.logo, only_path: true)
    end
    if appearance&.favicon&.attached?
      data[:favicon_url] = Rails.application.routes.url_helpers.rails_blob_path(appearance.favicon, only_path: true)
    end

    render_success(data: data)
  end

  # GET /api/v1/friend_links
  def friend_links
    if SiteSetting.get("friend_links_enabled", default: "false") != "true"
      return render_success(data: [])
    end

    links = FriendLink.active.ordered
    render_success(
      data: links.map do |l|
        { id: l.id, name: l.name, url: l.url, description: l.description, logo: l.logo, sort_order: l.sort_order }
      end
    )
  end
end
