class Admin::ThemesController < Admin::DashboardController
  before_action :require_super_admin!
  before_action :set_theme, only: [:activate, :deactivate, :destroy, :screenshot, :edit, :update]

  def index
    @themes = Theme.where.not(identifier: Theme::BUILTIN_IDENTIFIER).order(created_at: :desc)
    @default_theme = Theme.default_theme
    @active_theme = Theme.active_theme
  end

  def create
    zip_file = params[:theme_zip]
    unless zip_file.present?
      redirect_to admin_themes_path, alert: t("admin.flash.m134")
      return
    end

    # 先校验
    tmp_path = save_temp_zip(zip_file)
    errors = Myapp::ThemeManager.instance.validate_zip(tmp_path)
    unless errors.empty?
      File.delete(tmp_path) if File.exist?(tmp_path)
      redirect_to admin_themes_path, alert: "主题包校验失败: #{errors.join(', ')}"
      return
    end

    # 读取 theme.json 获取 identifier
    identifier = extract_identifier(tmp_path)
    if identifier.blank?
      File.delete(tmp_path) if File.exist?(tmp_path)
      redirect_to admin_themes_path, alert: t("admin.flash.m087")
      return
    end

    # 检查是否已存在
    existing = Theme.find_by(identifier: identifier)
    if existing
      existing.destroy_theme!
    end

    theme = Theme.create!(
      name: identifier,
      identifier: identifier,
      version: "0.0.0"
    )

    begin
      Myapp::ThemeManager.instance.install_from_zip(tmp_path, theme)
      redirect_to admin_themes_path, notice: t("admin.flash.m013", name: @theme.name)
    rescue => e
      theme.destroy
      redirect_to admin_themes_path, alert: t("admin.flash.m015", message: e.message)
    ensure
      File.delete(tmp_path) if File.exist?(tmp_path)
    end
  end

  def edit
  end

  def update
    style = params.dig(:settings, :topic_list_style)
    unless %w[article image_text].include?(style)
      redirect_to edit_admin_theme_path(@theme), alert: t("admin.flash.m007")
      return
    end
    @theme.update_settings!("topic_list_style" => style)
    redirect_to edit_admin_theme_path(@theme), notice: t("admin.ui.m398")
  end

  def activate
    @theme.activate!
    Rails.cache.delete("active_theme_css")
    Rails.cache.delete("active_theme_dark_css")
    redirect_to admin_themes_path, notice: t("admin.flash.m011", name: @theme.name)
  end

  def deactivate
    @theme.deactivate!
    Rails.cache.delete("active_theme_css")
    Rails.cache.delete("active_theme_dark_css")
    redirect_to admin_themes_path, notice: t("admin.flash.m049")
  end

  def reset
    if Theme.reset_to_default!
      Rails.cache.delete("active_theme_css")
      Rails.cache.delete("active_theme_dark_css")
      redirect_to admin_themes_path, notice: t("admin.flash.m058")
    else
      redirect_to admin_themes_path, alert: t("admin.flash.m153")
    end
  end

  def destroy
    if @theme.builtin_default?
      redirect_to admin_themes_path, alert: t("admin.flash.m023")
      return
    end
    name = @theme.name
    @theme.destroy_theme!
    Rails.cache.delete("active_theme_css")
    Rails.cache.delete("active_theme_dark_css")
    redirect_to admin_themes_path, notice: t("admin.flash.m012", name: name)
  end

  def screenshot
    path = @theme.screenshot_path
    if path
      send_file path, type: "image/png", disposition: "inline", cache_control: "public, max-age=86400"
    else
      head :not_found
    end
  end

  private

  def set_theme
    @theme = Theme.find(params[:id])
  end

  def require_super_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: t("admin.flash.m085")
    end
  end

  def save_temp_zip(zip_file)
    dir = Rails.root.join("tmp", "theme_uploads")
    FileUtils.mkdir_p(dir)
    path = dir.join("#{SecureRandom.hex(8)}.zip")
    File.binwrite(path, zip_file.read)
    path
  end

  def extract_identifier(zip_path)
    require "zip"
    Zip::File.open(zip_path) do |zip|
      entry = zip.find_entry("theme.json") || zip.find_entry { |e| e.name.end_with?("/theme.json") }
      next unless entry

      metadata = JSON.parse(entry.get_input_stream.read)
      metadata["identifier"]&.to_s&.downcase&.gsub(/[^a-z0-9_]/, "_")
    end
  rescue JSON::ParserError, StandardError
    nil
  end
end
