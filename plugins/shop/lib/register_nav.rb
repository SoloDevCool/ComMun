# register_nav.rb - 注册前台导航项

if config['show_in_nav'] != false
  Myapp::PluginManager.instance.add_nav_item(
    label: config['nav_label'] || '能量商城',
    path: '/shop',
    icon: config['nav_icon'] || 'bi-shop',
    order: 25,
    plugin: plugin
  )
end
