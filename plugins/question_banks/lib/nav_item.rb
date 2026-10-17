# nav_item.rb
# 注册前台导航项

Myapp::PluginManager.instance.add_nav_item(
  label: '题库',
  path: '/question_banks',
  icon: 'bi-journal-bookmark',
  order: 30,
  plugin: plugin
)
