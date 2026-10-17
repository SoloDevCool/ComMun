# init.rb - 插件入口文件
# 在插件被启用时执行

logger.info "[#{plugin.identifier}] Hello World 插件已加载！"
logger.info "[#{plugin.identifier}] 配置: greeting_message=#{config['greeting_message']}"

# 初始化完成后无需额外操作
# 钩子处理器在 hooks.json 中注册，会由 PluginManager 自动管理
