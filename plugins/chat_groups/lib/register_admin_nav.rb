# register_admin_nav.rb - 注册后台导航项

Myapp::PluginManager.instance.add_admin_nav_item(
  label: '交流群管理',
  path: '/admin/chat_groups',
  icon: 'bi-people',
  order: 30,
  group: '交流群管理',
  plugin: plugin
)
