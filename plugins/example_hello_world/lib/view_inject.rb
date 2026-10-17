# view_inject.rb
# 视图注入

if config['show_greeting'] != false
  message = ERB::Util.html_escape(config['greeting_message'] || 'Hello from Commun!')
  Myapp::PluginManager.instance.add_view_injection(
    location: 'home_before_content',
    content: "<div style=\"background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 12px 20px; text-align: center; border-radius: 8px; margin-bottom: 16px;\">#{message}</div>",
    plugin: plugin
  )
end
