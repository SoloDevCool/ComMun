# register_admin_nav.rb - 注册后台导航项

Myapp::PluginManager.instance.add_admin_nav_item(
  label: '荣誉榜管理',
  path: '/admin/honors',
  icon: 'bi-trophy',
  order: 40,
  group: '荣誉榜',
  plugin: plugin
)
