class Plugin < ApplicationRecord
  VALID_STATUSES = %w[uninstalled installed enabled disabled].freeze
  HOOK_TYPES = %w[
    before_action
    after_action
    around_action
    before_filter
    after_filter
    on_topic_create
    on_topic_update
    on_topic_destroy
    on_comment_create
    on_comment_update
    on_comment_destroy
    on_user_register
    on_user_login
    on_plugin_enabled
    on_plugin_disabled
    setup
    nav_item
    admin_nav_item
    view_injection
  ].freeze

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9_]+\z/, message: "只允许小写字母、数字和下划线" }
  validates :version, presence: true, format: { with: /\A\d+\.\d+\.\d+\z/, message: "版本号格式应为 x.y.z" }
  validates :status, inclusion: { in: VALID_STATUSES }

  scope :enabled, -> { where(status: "enabled") }
  scope :installed, -> { where(status: %w[installed enabled disabled]) }
  scope :disabled, -> { where(status: "disabled") }

  # 判断指定标识的插件是否处于启用状态（供核心代码判定插件功能开关）
  def self.enabled?(identifier)
    enabled.exists?(identifier: identifier)
  rescue StandardError
    false
  end

  before_validation :normalize_identifier

  def self.plugin_directory
    Rails.root.join("plugins")
  end

  def plugin_dir
    self.class.plugin_directory.join(identifier)
  end

  def plugin_entry_file
    plugin_dir.join("init.rb")
  end

  def enable!
    update!(status: "enabled")
    Myapp::PluginManager.instance.reload_plugin(self)
    Myapp::PluginManager.instance.fire_global_hook("on_plugin_enabled", self)
  end

  def disable!
    Myapp::PluginManager.instance.fire_global_hook("on_plugin_disabled", self)
    update!(status: "disabled")
    Myapp::PluginManager.instance.unload_plugin(self)
  end

  def uninstall!
    Myapp::PluginManager.instance.fire_global_hook("on_plugin_disabled", self) if enabled?
    Myapp::PluginManager.instance.unload_plugin(self)
    FileUtils.rm_rf(plugin_dir) if plugin_dir.exist?
    update!(status: "uninstalled", hooks: {}, config: {})
  end

  def enabled?
    status == "enabled"
  end

  def installed?
    %w[installed enabled disabled].include?(status)
  end

  def status_text
    case status
    when 'enabled'    then '已启用'
    when 'installed'  then '已安装'
    when 'disabled'   then '已禁用'
    when 'uninstalled' then '未安装'
    else status
    end
  end

  def has_entry_file?
    plugin_entry_file.exist?
  end

  def read_config_schema
    schema_file = plugin_dir.join("config_schema.json")
    return {} unless schema_file.exist?

    JSON.parse(schema_file.read)
  rescue JSON::ParserError
    {}
  end

  def read_readme
    readme_file = plugin_dir.join("README.md")
    return "" unless readme_file.exist?

    readme_file.read
  end

  def load_hooks!
    hooks_file = plugin_dir.join("hooks.json")
    return if hooks_file.blank? || !hooks_file.exist?

    self.hooks = JSON.parse(hooks_file.read)
    save!
  rescue JSON::ParserError
    self.hooks = {}
  end

  private

  def normalize_identifier
    self.identifier = identifier.to_s.downcase.gsub(/[^a-z0-9_]/, "_").gsub(/_+/, "_").gsub(/\A_|_\z/, "") if identifier.present?
  end
end
