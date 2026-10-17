require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Myapp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.autoload_paths << Rails.root.join("app/services")

    # 插件 MVC 支持：将各插件的 app 子目录加入 autoload 与视图查找路径，
    # 使插件可以自带模型、控制器、辅助方法与视图（如 question_banks 插件）。
    # 注意：不能把 plugins 根目录整体作为 autoload 路径，否则同一文件会被多个根管理。
    Dir[Rails.root.join("plugins/*/app/models")].each { |p| config.autoload_paths << p }
    Dir[Rails.root.join("plugins/*/app/controllers")].each { |p| config.autoload_paths << p }
    Dir[Rails.root.join("plugins/*/app/helpers")].each { |p| config.autoload_paths << p }
    Dir[Rails.root.join("plugins/*/app/jobs")].each { |p| config.autoload_paths << p }
    Dir[Rails.root.join("plugins/*/app/views")].each { |p| config.paths["app/views"].push(p) }

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # 允许 ActiveStorage 以内联方式提供 SVG（否则会被当作 text/plain 下载，无法在 <img> 中显示）
    config.active_storage.content_types_allowed_inline += ["image/svg+xml"]

    config.time_zone = "Beijing"
    config.active_record.default_timezone = :local
    config.i18n.default_locale = :"zh-CN"
    # 支持的语言：简体中文、英文；预留日语、韩语（翻译文件补齐后即可启用）
    config.i18n.available_locales = [:"zh-CN", :en, :ja, :ko]
    # 缺失翻译时回退到默认语言（简体中文）
    config.i18n.fallbacks = true
    # 加载 config/locales 下所有子目录中的翻译文件（按模块拆分）
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
