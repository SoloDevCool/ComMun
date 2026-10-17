# admin_nav.rb
# 注册后台导航项

Myapp::PluginManager.instance.add_admin_nav_item(
  label: '示例统计',
  path: '/admin',
  icon: 'bi-graph-up',
  order: 99,
  group: '扩展管理',
  plugin: plugin
)
