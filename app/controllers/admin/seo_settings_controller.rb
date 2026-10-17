class Admin::SeoSettingsController < Admin::DashboardController
  before_action :require_super_admin!
  def index
    @license_valid = license_valid?
    @settings = {
      site_name: SiteSetting.get("site_name", default: ""),
      seo_site_name: SiteSetting.get("seo_site_name", default: ""),
      seo_title: SiteSetting.get("seo_title", default: ""),
      seo_description: SiteSetting.get("seo_description", default: ""),
      seo_keywords: SiteSetting.get("seo_keywords", default: ""),
      seo_og_image: SiteSetting.get("seo_og_image", default: ""),
      seo_footer_html: SiteSetting.get("seo_footer_html", default: ""),
      seo_google_verification: SiteSetting.get("seo_google_verification", default: ""),
      seo_bing_verification: SiteSetting.get("seo_bing_verification", default: ""),
      seo_baidu_verification: SiteSetting.get("seo_baidu_verification", default: ""),
      clarity_project_id: SiteSetting.get("clarity_project_id", default: ""),
      indexnow_enabled: SiteSetting.get("indexnow_enabled", default: "false"),
      indexnow_key: SiteSetting.get("indexnow_key", default: "")
    }
  end

  def update
    unless license_valid?
      redirect_to admin_settings_path, alert: t("admin.flash.m008")
      return
    end

    old_key = SiteSetting.get("indexnow_key", default: "")
    new_key = params[:settings].dig("indexnow_key").to_s.strip

    params[:settings].each do |key, value|
      SiteSetting.set(key, value)
    end

    # 管理 IndexNow key 文件
    manage_indexnow_key_file(old_key, new_key)

    redirect_to admin_seo_settings_path, notice: "SEO 设置已保存"
  end

  private

  def manage_indexnow_key_file(old_key, new_key)
    # 删除旧 key 文件
    if old_key.present?
      old_path = Rails.public_path.join("#{old_key}.txt")
      FileUtils.rm_f(old_path) if old_path.exist?
    end
    # 创建新 key 文件
    if new_key.present?
      new_path = Rails.public_path.join("#{new_key}.txt")
      FileUtils.mkdir_p(new_path.dirname)
      new_path.write(new_key)
    end
  end

  def require_super_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: t("admin.flash.m085")
    end
  end
end
