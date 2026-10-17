# admin_nav.rb
# 注册后台导航项（题库管理分组）

Myapp::PluginManager.instance.add_admin_nav_item(
  label: '题库科目',
  path: '/admin/qb_exams',
  icon: 'bi-journal-bookmark',
  order: 41,
  group: '题库管理',
  plugin: plugin
)

Myapp::PluginManager.instance.add_admin_nav_item(
  label: '投稿审核',
  path: '/admin/qb_reviews',
  icon: 'bi-clipboard-check',
  order: 42,
  group: '题库管理',
  plugin: plugin
)
