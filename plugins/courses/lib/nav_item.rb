# nav_item.rb
# 注册前台导航项

Myapp::PluginManager.instance.add_nav_item(
  label: '课程',
  path: '/courses',
  icon: 'bi-mortarboard',
  order: 20,
  plugin: plugin
)
