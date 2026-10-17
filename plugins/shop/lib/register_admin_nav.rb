# register_admin_nav.rb - 注册后台导航项

Myapp::PluginManager.instance.add_admin_nav_item(
  label: '能量商城',
  path: '/admin/shop_items',
  icon: 'bi-shop',
  order: 30,
  group: '能量商城管理',
  plugin: plugin
)
