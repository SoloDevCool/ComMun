# on_topic_create.rb
# 帖子创建后触发的钩子处理器
#
# 可用变量:
#   args[0] - Topic 实例
#   plugin - 当前插件实例
#   config - 插件配置
#   logger - Rails.logger

topic = args[0] if defined?(args)
if topic
  logger.info "[#{plugin.identifier}] 新帖子创建: #{topic.title}"
end
