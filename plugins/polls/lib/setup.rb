# setup.rb - 插件加载时向核心 Topic 模型挂载投票关联
#
# 说明：dev 模式下 Topic 类会被代码重载重建，
# reloader.to_prepare 中的 load_all! 会重新执行本脚本完成重新挂载。
# 注意：钩子脚本运行在 Object 实例上下文中，模块名不能带命名空间
# （`module A::B` 需要常量 A 已存在），故使用顶级模块名。

module PollsTopicExtension
  extend ActiveSupport::Concern

  included do
    has_one :poll, dependent: :destroy
    accepts_nested_attributes_for :poll, allow_destroy: true, reject_if: :reject_poll
  end

  # 创建/编辑话题表单中投票选项为空时忽略嵌套属性
  def reject_poll(attributes)
    h = attributes.respond_to?(:to_unsafe_h) ? attributes.to_unsafe_h : attributes
    opts = h["poll_options_attributes"]
    opts.blank? || opts.all? { |_, v| v["title"].blank? }
  end
end

Topic.include(PollsTopicExtension)
