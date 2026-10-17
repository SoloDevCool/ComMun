require "zip"

# 确保 plugins 目录存在
plugins_dir = Rails.root.join("plugins")
FileUtils.mkdir_p(plugins_dir) unless plugins_dir.exist?

# 延迟加载所有已启用的插件
# 使用 reloader.to_prepare：生产环境仅在启动时执行一次；
# 开发环境在每次代码重载后重新执行（autoload_lib 会重建 PluginManager 单例，
# 否则重载后视图注入/导航注册会丢失）
Rails.application.reloader.to_prepare do
  if ActiveRecord::Base.connection.table_exists?("plugins")
    Myapp::PluginManager.instance.load_all!
  end
end
