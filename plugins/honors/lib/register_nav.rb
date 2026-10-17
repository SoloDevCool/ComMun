# register_nav.rb - 注册前台导航项

if config['show_in_nav'] != false
  Myapp::PluginManager.instance.add_nav_item(
    label: config['nav_label'] || '荣誉榜',
    path: '/honors',
    icon: config['nav_icon'] || 'bi-trophy',
    order: 70,
    plugin: plugin
  )
end
