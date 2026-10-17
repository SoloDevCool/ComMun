require_dependency "admin/dashboard_controller"

class Admin::PluginsController < Admin::DashboardController
  before_action :set_plugin, only: [ :show, :enable, :disable, :uninstall, :update_config ]

  def index
    @plugins = Plugin.order(:name)
  end

  def show
    @readme = @plugin.read_readme
    @config_schema = @plugin.read_config_schema
    @config_values = @plugin.config || {}
  end

  def new
    @plugin = Plugin.new
  end

  def scan_local
    plugins_dir = Rails.root.join("plugins")
    installed = 0

    Dir.glob(plugins_dir.join("*", "plugin.json")).each do |json_file|
      metadata = JSON.parse(File.read(json_file))
      identifier = metadata["identifier"]

      next unless identifier

      plugin = Plugin.find_or_initialize_by(identifier: identifier)
      next if plugin.persisted?

      plugin.assign_attributes(
        name: metadata["name"],
        version: metadata["version"],
        description: metadata["description"],
        author: metadata["author"],
        homepage: metadata["homepage"],
        metadata: metadata,
        status: "installed"
      )
      plugin.save!
      installed += 1
    rescue StandardError => e
      Rails.logger.error("[PluginManager] 扫描本地插件失败 #{json_file}: #{e.message}")
    end

    redirect_to admin_plugins_path, notice: installed > 0 ? "成功扫描并安装 #{installed} 个本地插件" : "未发现新的本地插件"
  end

  def create
    @plugin = Plugin.new(plugin_params)

    if params[:plugin][:package_file].present?
      zip_path = params[:plugin][:package_file].path
      filename = params[:plugin][:package_file].original_filename

      unless filename.end_with?(".zip")
        @plugin.errors.add(:base, "仅支持 .zip 格式的插件包")
        render :new, status: :unprocessable_content
        return
      end

      # 验证 ZIP
      errors = Myapp::PluginManager.instance.validate_plugin_zip(zip_path)
      if errors.any?
        @plugin.errors.add(:base, errors.join("; "))
        render :new, status: :unprocessable_content
        return
      end

      # 从 plugin.json 提取标识符
      begin
        require "zip"
        metadata = nil
        Zip::File.open(zip_path) do |zip_file|
          entry = zip_file.find_entry("plugin.json") || zip_file.glob("**/plugin.json").first
          metadata = JSON.parse(entry.get_input_stream.read) if entry
        end

        if metadata
          @plugin.identifier = metadata["identifier"] || @plugin.identifier
          @plugin.name = metadata["name"] || @plugin.name
          @plugin.version = metadata["version"] || @plugin.version
          @plugin.description = metadata["description"] || @plugin.description
          @plugin.author = metadata["author"] || @plugin.author
          @plugin.homepage = metadata["homepage"] || @plugin.homepage
        end
      rescue StandardError
        @plugin.errors.add(:base, "无法读取 plugin.json")
        render :new, status: :unprocessable_content
        return
      end

      if @plugin.save
        # 安装插件文件
        begin
          Myapp::PluginManager.instance.install_plugin_from_zip(zip_path, @plugin)
          redirect_to admin_plugins_path, notice: t("admin.flash.m072", name: @plugin.name)
        rescue StandardError => e
          @plugin.destroy
          @plugin.errors.add(:base, e.message)
          render :new, status: :unprocessable_content
        end
      else
        render :new, status: :unprocessable_content
      end
    else
      @plugin.errors.add(:base, "请上传插件包文件")
      render :new, status: :unprocessable_content
    end
  end

  def enable
    begin
      @plugin.enable!
      redirect_to admin_plugins_path, notice: t("admin.flash.m073", name: @plugin.name)
    rescue StandardError => e
      redirect_to admin_plugins_path, alert: "启用失败: #{e.message}"
    end
  end

  def disable
    begin
      @plugin.disable!
      redirect_to admin_plugins_path, notice: t("admin.flash.m074", name: @plugin.name)
    rescue StandardError => e
      redirect_to admin_plugins_path, alert: "禁用失败: #{e.message}"
    end
  end

  def uninstall
    begin
      name = @plugin.name
      @plugin.uninstall!
      redirect_to admin_plugins_path, notice: t("admin.flash.m075", name: name)
    rescue StandardError => e
      redirect_to admin_plugins_path, alert: "卸载失败: #{e.message}"
    end
  end

  def update_config
    if @plugin.update(config: plugin_config_params)
      redirect_to admin_plugin_path(@plugin), notice: t("admin.flash.m147")
    else
      redirect_to admin_plugin_path(@plugin), alert: t("admin.flash.m146")
    end
  end

  private

  def set_plugin
    @plugin = Plugin.find(params[:id])
  end

  def plugin_params
    params.require(:plugin).permit(:name, :identifier, :version, :description, :author, :homepage)
  end

  def plugin_config_params
    return {} if params[:plugin_config].blank?

    params.require(:plugin_config).permit!
  end
end
