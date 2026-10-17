class Theme < ApplicationRecord
  VALID_STATUSES = %w[installed active].freeze
  BUILTIN_IDENTIFIER = "default".freeze

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9_]+\z/, message: "只允许小写字母、数字和下划线" }
  validates :version, presence: true, format: { with: /\A\d+\.\d+\.\d+\z/, message: "版本号格式应为 x.y.z" }
  validates :status, inclusion: { in: VALID_STATUSES }

  scope :active, -> { where(status: "active") }
  scope :installed, -> { where(status: "installed") }

  before_validation :normalize_identifier

  def self.theme_directory
    Rails.root.join("themes")
  end

  def theme_dir
    self.class.theme_directory.join(identifier)
  end

  def self.active_theme
    find_by(status: "active")
  end

  def self.default_theme
    find_by(identifier: BUILTIN_IDENTIFIER)
  end

  def builtin_default?
    identifier == BUILTIN_IDENTIFIER
  end

  def active?
    status == "active"
  end

  def activate!
    Theme.transaction do
      Theme.where(status: "active").update_all(status: "installed")
      update!(status: "active")
    end
  end

  def deactivate!
    update!(status: "installed") if active?
  end

  def destroy_theme!
    if builtin_default?
      errors.add(:base, "内置默认主题不可删除")
      return false
    end
    deactivate!
    FileUtils.rm_rf(theme_dir) if theme_dir.exist?
    destroy!
  end

  def self.reset_to_default!
    default = default_theme
    return false unless default

    Theme.transaction do
      Theme.where(status: "active").update_all(status: "installed")
      default.update!(status: "active")
    end
    true
  end

  def read_styles_css
    read_theme_file("styles.css")
  end

  def read_custom_css
    read_theme_file("custom.css")
  end

  def read_dark_css
    read_theme_file("dark.css")
  end

  def screenshot_path
    path = theme_dir.join("screenshot.png")
    path.exist? ? path : nil
  end

  # 主题级展示设置（存储在 metadata["settings"] 中，随主题持久化）
  def settings
    metadata.is_a?(Hash) && metadata["settings"].is_a?(Hash) ? metadata["settings"] : {}
  end

  # 主题列表样式：article = 文章列表模式（默认），image_text = 图文列表模式
  def topic_list_style
    settings["topic_list_style"].presence || "article"
  end

  def update_settings!(new_settings)
    meta = metadata.is_a?(Hash) ? metadata.dup : {}
    meta["settings"] = settings.merge(new_settings.stringify_keys)
    update!(metadata: meta)
  end

  private

  def normalize_identifier
    self.identifier = identifier.to_s.downcase.gsub(/[^a-z0-9_]/, "_").gsub(/_+/, "_").gsub(/\A_|_\z/, "") if identifier.present?
  end

  def read_theme_file(filename)
    path = theme_dir.join(filename)
    path.exist? ? path.read : nil
  end
end
