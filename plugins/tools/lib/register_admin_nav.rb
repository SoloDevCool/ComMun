# register_admin_nav.rb - 注册后台导航项

Myapp::PluginManager.instance.add_admin_nav_item(
  label: '工具分类',
  path: '/admin/tool_categories',
  icon: 'bi-tools',
  order: 30,
  group: '工具集管理',
  plugin: plugin
)

Myapp::PluginManager.instance.add_admin_nav_item(
  label: '工具管理',
  path: '/admin/tools',
  icon: 'bi-box',
  order: 31,
  group: '工具集管理',
  plugin: plugin
)
