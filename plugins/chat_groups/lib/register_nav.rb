# register_nav.rb - 注册前台导航项

if config['show_in_nav'] != false
  Myapp::PluginManager.instance.add_nav_item(
    label: config['nav_label'] || '交流群',
    path: '/chat_groups',
    icon: config['nav_icon'] || 'bi-people',
    order: 30,
    plugin: plugin
  )
end
