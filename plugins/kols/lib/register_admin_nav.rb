# register_admin_nav.rb - 注册后台导航项
Myapp::PluginManager.instance.add_admin_nav_item(
  label: 'KOL达人管理',
  path: '/admin/kols',
  icon: 'bi-stars',
  order: 30,
  group: 'KOL达人',
  plugin: plugin
)
