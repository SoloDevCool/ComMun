# register_nav.rb - 注册前台导航项
if config['show_in_nav'] != false
  Myapp::PluginManager.instance.add_nav_item(
    label: config['nav_name'] || 'KOL达人',
    path: '/kols',
    icon: config['nav_icon'] || 'bi-stars',
    order: 60,
    plugin: plugin
  )
end
