# init.rb - 话题投票插件入口
#
# 插件加载时通过 setup 钩子（lib/setup.rb）向核心 Topic 模型挂载投票关联：
#   has_one :poll、accepts_nested_attributes_for :poll
#
# 功能：
#   - 创建/编辑话题时可附加投票（2-10 个选项）
#   - 登录用户参与投票（不能投自己的票），实时更新票数与百分比
#   - 话题作者可关闭/重开/删除投票；投票后通知话题作者
#   - 拥有 polls.manage 权限点的角色可管理任意投票
#
# 插件停用时：投票 UI 隐藏、投票接口拒绝、Topic 挂载卸载（现有数据保留）。
