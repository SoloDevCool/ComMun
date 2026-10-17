

# 示例插件：hello_world
# 这是一个最简单的插件示例，展示插件系统的基本功能

module PluginHookable
  extend ActiveSupport::Concern

  included do
    # 在帖子创建后触发插件钩子
    after_create :fire_plugin_after_create, if: :should_fire_plugin_hooks?
    after_update :fire_plugin_after_update, if: :should_fire_plugin_hooks?
    before_destroy :fire_plugin_before_destroy, if: :should_fire_plugin_hooks?
  end

  private

  def should_fire_plugin_hooks?
    self.class.name.in?(%w[Topic Comment User])
  end

  def fire_plugin_after_create
    hook_name = "on_#{self.class.name.downcase}_create"
    Myapp::PluginManager.instance.fire_global_hook(hook_name, self)
  end

  def fire_plugin_after_update
    hook_name = "on_#{self.class.name.downcase}_update"
    Myapp::PluginManager.instance.fire_global_hook(hook_name, self)
  end

  def fire_plugin_before_destroy
    hook_name = "on_#{self.class.name.downcase}_destroy"
    Myapp::PluginManager.instance.fire_global_hook(hook_name, self)
  end
end
