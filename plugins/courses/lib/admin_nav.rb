# admin_nav.rb
# 注册后台导航项（课程管理分组）

Myapp::PluginManager.instance.add_admin_nav_item(
  label: '课程管理',
  path: '/admin/courses',
  icon: 'bi-mortarboard',
  order: 51,
  group: '课程管理',
  plugin: plugin
)

Myapp::PluginManager.instance.add_admin_nav_item(
  label: '课程方向',
  path: '/admin/course_directions',
  icon: 'bi-compass',
  order: 52,
  group: '课程管理',
  plugin: plugin
)

Myapp::PluginManager.instance.add_admin_nav_item(
  label: '讲师管理',
  path: '/admin/instructors',
  icon: 'bi-person-badge',
  order: 53,
  group: '课程管理',
  plugin: plugin
)
