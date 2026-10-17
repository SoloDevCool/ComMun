# register_nav.rb - 注册前台导航项

if config['show_in_nav'] != false
  Myapp::PluginManager.instance.add_nav_item(
    label: config['nav_label'] || '工具集',
    path: '/tools',
    icon: config['nav_icon'] || 'bi-tools',
    order: 20,
    plugin: plugin
  )
end
