# nav_item.rb
# 注册前台导航项

Myapp::PluginManager.instance.add_nav_item(
  label: '示例插件',
  path: '/topics',
  icon: 'bi-stars',
  order: 90,
  plugin: plugin
)
